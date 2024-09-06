---
layout: blogpost
title: "CandyStore: the Road to Consistency"
description: "A reply to the reddit discussion on CandyStore"
imageurl: /static/res/2024-09-06-reddit.png
imagetitle: "Someone is wrong on the internet"
---

We (Sweet Security) published a [post on Reddit](https://www.reddit.com/r/rust/comments/1f4ahc2/a_novel_o1_keyvalue_store_candystore/) 
to tell the Rust community about [CandyStore](/blog/candystore), our fast key-value store, and I feel there were some recurring
themes that I did not address on the first post. I tried answering specific comments, but it's clear there's been 
some misunderstanding around the purpose and the mechanics of Candy, and that's the purpose of this post.

## But First
First of all, an important update: CandyStore now **supports non-blocking compaction**. This is an important milestone,
as compactions happen rather frequently. Data is only *appended* to the file, so inserting and removing keys,
or updating a key over and over, produces waste. Up until now, the entire shard was locked and compacted: the 
"surviving" entries were copied to a *target* shard file and then the original file was atomically replaced with 
the target. Other shards could still be accessed, but any shard that was ongoing compaction could not.

<img src="/static/res/2024-09-06-sweep.png" title="Under the rug" class="blog-post-image">

Non-blocking compaction works on a row-level, not on a shard level: each row of the shard is compacted consecutively 
in a background thread (using a thread-pool to limit the concurrency), and the rest of the rows remain accessible. 
Basically compaction now maintains the original and target files simultaneously, and rows up to a certain index are
served by the target file, and rows above that certain index are served by the original file, until the job is done.

Note that splits are still blocking, but they happen much less frequently than compactions. A DB is expected to store
a "somewhat constant" number of keys -- after all, your disk space is also limited. You can either specify a pre-split
in advance, or expect to have splits in the beginning, after which the number of entries stabilizes and further splits
are unlikely.

## Back to Reddit

Overall, the post was very well accepted and some good questions and suggestions came up. Generally speaking, three 
recurring themes kept coming up: the **purpose** it serves, what **consistency** means, and **mmap being a bad choice**
for databases. Let's dive in.

### Purpose: Anti-Cache

The main purpose of CandyStore is the reverse of a cache: to offload data to file, while making it very cheap
to pull it back in when needed. We need to conserve RAM, and as [cgroups have issues](https://www.reddit.com/r/devops/comments/gvf2mi/force_page_reclaim_in_cgroups_when_their_cache/)
with page-cache accounting that could lead to OOMs, we explicitly do not want to keep a large cache. 
Alternatives like [cachelib](https://cachelib.org/) or [slotmap](https://docs.rs/slotmap/latest/slotmap/) do the 
opposite - they are persistent caches, trying to keep as much data in memory as possible. 

### Crash-Safety

A major concern (and justly so) was *process-crash consistency* vs *machine-crash consistency*: Candy can happily 
survive process crashes (there's even [CandyCrasher](https://github.com/sweet-security/candystore/tree/main/candy-crasher) 
which does just that) since we never overwrite data and the mmap table will be automatically flushed on process 
termination. However, we cannot rely on the state of the mmap table after a machine crash, power failure, etc.,
and this would lead us to an inconsistent state.

<img src="/static/res/2024-09-06-crash.png" title="crash" class="blog-post-image">

That is a valid point, but that was explicitly out of scope for Candy's design goals. We mostly care about process
crashes (e.g., OOM kills) or sensor upgrades, where the DB allows to skip reconstructing the state. Much of this
state would be irrelevant after a reboot anyhow, and we can safely start anew in such cases.

The important question then becomes, **how can we tell if the DB is a consistent state?** Well, that's actually a bug, 
and I'll address that in the next section.

Do keep in mind though, that any "really persistent" solution would either require sync'ing data to disk on 
every operation (i.e., introduce disk latency to every insert/remove) or require keeping a WAL to aggregate several
writes together, and flush them to disk more efficiently. Either way, it will stall your operations until they're 
backed by a file, and for 99% of the time that's something we can live without.

Scale-out solutions like Cassandra, who want to make use of the page cache, replicate writes to 3 nodes 
(*write consistency*) and read them from 2 nodes (*read consistency*), to be able to cope with machine crashes. We're
in-process and don't have that privielge.

### Mmap and Other Beasts

Mmap is [not a reliable mechanism for persistence](https://www.youtube.com/watch?v=1BRGU_AS25c). It offers largely 
unpredictable performance, page eviction is single threaded in the kernel, and worst, it will delegate any underlying 
IO error as a `SIGBUS` -- out of the blue! What were we even thinking using it?!

<img src="/static/res/2024-09-06-holding.png" title="holding it wrong" class="blog-post-image">

Well, it depends on how you hold it:

* We only rely on mmap for the shard's header table, which consists of a fixed number of pages. Data is written 
  using normal IO system calls. 
* It serves the purpose of reducing our memory footprint, as the data can be evicted at any time by the kernel.
* It is flushed efficiently (in bulk) to disk, so saves up on IOPS.
* We don't have transactions, so we don't concern ourselves with Copy-on-Write or partial flushes.
* It is a cheap way to ensure process-crash consistency since it will be flushed on termination. 
* We haven't experienced any `SIGBUS`s so far, and we have thousands of sensors running over containers with
  EBS mounts. I guess it's just not that common.

But it's clearly an achilles heel of Candy, if only because we can't tell that we're recovering from a machine 
crash, which means the DB is inconsistent. We need a better way to do it.

## Reboot Consistency

If we give up on eviction of the shard table, and require the table to be `malloc`ed, we can use a form of 
a journal to achieve full crash consistency: The shard's table remains as-is, but instead of being mmap'ed in, it's
just read into memory. Apart from the table, we'd hold several *journal blocks*, each 4KB in size, which should have 
room for ~290 entries per block.

<img src="/static/res/2024-09-06-panic.png" title="kernel panic" class="blog-post-image">

The algorithm keeps working the same, but after updating the table (which is no longer mmap'ed) we'd append an entry
to the current journal block: 2 bytes for the row selector, 4 bytes for the signature, and 8 bytes for the data offset. 
Once this journal fills up, we'd flush it to file. This means you may lose up to ~290 updates/shard if you crashed, 
but that would be deemed acceptable. We can also flush them every so often regardless of fullness.

Once enough journal blocks fill up, say 10, we'd flush the whole shard table to disk and clear the journal blocks.
The file would hold a two slots for tables, and each time we'd writing to the next (cyclically) slot, so that when 
we load the table we'd select the latest *in tact* version of it, and apply the journal in-memory.

This scheme should ensure we don't require too many of IOPS, while allowing us to recover cleanly from all sorts 
of crashes -- at the cost of requiring non-evictable tables.

## Some Future Directions

I'm mulling over in-place modification, to save on compactions. That would be mostly useful or lists, where
the chain elements are fixed-sized and very small, and can be made 4KB-aligned. This means that updating them in-place
should be "transactional" in nature, and crashing should be okay. 

If this proves to be the case, I will also want to add *wide lists* (or rather, lists of *wide-elements*): combining 
multiple small elements into a single entry. This is useful to us as it would make list iteration much faster, 
at the cost of losing O(1) access to list elements. We could still access them, but it'd require loading the whole
wide-element and looking up the one we want in it.

Just sharing some raw ideas here.
