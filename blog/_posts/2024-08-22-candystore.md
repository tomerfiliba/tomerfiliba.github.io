---
layout: blogpost
title: A Sweet Key-Value Store
description: "CandyStore - a fast and efficient key-value store in pure Rust"
imageurl: /static/res/2024-08-15-candystore.jpeg
imagetitle: "Tasty bytes!"
draft: true
---

## TL;DR
*Sweet Security* has just released [CandyStore](https://github.com/sweet-security/candystore) - a **very fast Key-Value 
Store** with negligible memory overhead and unique features like lists and queues - in pure Rust. 
The library is meant to be used an *embedded database*, but in the future we may release a server and C bindings.

## Life, the Universe and Everything

Well, it's been ten years since I've felt like I have something interesting to share with the world. A short recap
of these years would reveal me having two kids (the eldest being 10 years old... I wonder if it has anything to do
with it?). I've had my fun time in the storage industry at [Weka](http://weka.io), where I've done everything from 
developing a super low-latency scheduler and inventing a network protocol, all the way to large-scale 
distributed algorithms. I've also had a glimpse of corporate life at ~~Facebook~~Meta and learned that (*surprise surprise*) 
it's not for me. 

<img src="/static/res/2024-08-15-cyber.jpg" title="Cyberliens" class="blog-post-image">

Nowadays I'm the CTO of [Sweet Security](https://sweet.security/) - we offer a whole *suite* of Runtime-based 
Cloud Security, like Detection & Response, Vulnerability Management, Non-Human Identities, and more. Amazing 
technology and people, for sure, but we're not here to talk about cyber security... we're here to *talk about storage?!*

You see, we develop a very lean sensor (in Rust) that runs on customers' workloads. Low resource consumption is of 
the essence, because production environments are not as forgiving as employees' laptops (think antivirus/EDR). 
In order to free some memory for more and more features, we had to move some of the state we keep in hash tables 
and lists to disk. Surely the answer is to take some battle-tested embedded database/key-value store (a DB that runs 
inside your app), such as `sqlite` or `rocksdb`, and move our data there. Right?

## On LSMs, B-Trees and Locking 

<img src="/static/res/2024-08-15-wal.png" title="O(1)" class="blog-post-image">

The short answer: we've tried ~5 mainstream and well-known embedded database and they all failed us. Some had bad 
perofmance, some had huge memory demands and some had inconsistent pefromance and deadlocks. We have multiple 
threads accessing data, or iterating while deleteing elements, and the DB must support such usage patterns.

In general, databases are either based on *B-Trees* (like binary search trees with "fat nodes") or 
*Log-Structured Merge (LSM)* trees, and most databases (if not all) require a *journal* or a *Write-Ahead Log (WAL)*. 
B-Trees are the de-facto standard way to implement indexing: they allow for cheap range queries. We specifically 
have no need for range queries, and in practice all B-Tree based databases tend to perform more slowly than ones 
based on LSMs. 

LSMs dominate the key-value store market, as they're optimized for write intensive workloads, and the principle 
behind them is neat: they keep entries in memory until they reach a certain size, then they sort the entries and 
dump them to disk in "generation-0" files. Whenever enough genration-0 files have accumulated, they compact (merge)
them into a single generation-1 file. This is easily done using merge-sort, since each file is internally sorted. 
Compaction is also the time to reclaim the space of any updated or deleted entries, as every update or delete 
produces a new version of the entry. At some point they will have accumulated enough generation-1 files, and then 
they'll compact those into generation-2 files, and so on. A cool feature/side effect of LSMs is the inherent 
support for *prefix search*, since the keys are already sorted.

The drawbacks are mainly the need for buffering large chunks in-memory before sorting them (requiring a WAL),
having `O(log(n))` lookups from disk, keeping lots of tombstones and versions of the same key, and having unbounded 
merges (each generation is exponentially larger than the previous one). They perform very well "now" while sweeping 
all the dirty work under the rug. On the implementation side, either they did not live to our performance
expectations, memory consumption, or ran into deadlocks when one thread was iterating while another was inserting.

## A Hash Table in a File?
Come to think of it, a hash table is probably the perfect container: as long as you don't care about relative order,
everything is `O(1)`! It has a minimal overhead in terms of memory and computation and it even scales-out well 
(sharding, consistent hashes, etc.). It does have a couple of drawbacks, namely *rehashing* when it gets full and 
pointer-chasing on collisions. These two constraints basically require keeping everything in-memory and trying to 
put a hash table in a file would have people questioning your sanity... So let's do it!

## Welcome to the CandyStore

Taking this idea a bit further brings us to [CandyStore](https://github.com/sweet-security/candystore): **a zero-overhead
extension of hash tables onto files**. It works like the part-tree part-hash chimera, taking advantage of the uniform
distribution of hashes in three ways. It splits a 64-bit hash into three components: a shard selector (16 bits), 
a row selector (16 bits), and a signature (32 bits).

<img src="/static/res/2024-08-22-candy.png" title="Sweet" class="blog-post-image">

The main concept is the `ShardFile`: it contains of all entries that have a certain hash prefix. In order to keep
resource comsumption minimal, CandyStore starts with just a single shard file covering the whole shard range, so in 
our case `[0-65536)`. Each shard file has a header table, made of rows, and each row is made of signatures. 
Immediately following the header table is the entries' data.

After reaching the correct shard file and row, using the selectors taken from the hash, we perform a parallel 
lookup (using SIMD instructions) over all of the signatures, finding the one we're looking for very quickly. 
Once a signature is found, the header table also contains its file offset and length, so we can go ahead of read it 
directly from the file.

With the default numbers of 64 rows per shard file, each with 512 signatures, a shard file is expect to hold ~30K 
entries (utilization of 90%). The chance of collisions (i.e., two different keys having the same signature) within 
a single row are 0.003%, so with 64 rows that's around 0.2% per shard file. This means that the probability we read 
the correct entry from the file is practically 100%. Since in persistent storage algoritms we care mostly about disk 
access, it means we have a O(1) way of fetching a key from the store.

What happens when a shard file becomes full? If a certain row reaches its 512 signature limit, we split the entire
shard file into a bottom half and a top half: we basically take an extra bit of the shard selector into consideration
when looking up the shard file. In our example, we started with a shard file covering `[0..65536)`, and we end up with
one covering `[0..32768)` and the other covering `[32768..65536)`. Now every entry whose MSB is 0 goes to the bottom
shard, and every entry with an MSB of 1 goes to the top shard. Assuming uniform distribution of hashes, each shard
will contain half of the entries of the original one, and we can rest assured the resulting tree will be *balanced*, 
because the tree is expected to be [complete](https://en.wikipedia.org/wiki/Binary_tree#Types_of_binary_trees).

Note that it's possible to incease the efficienty using a method similar to 
[Cuckoo hashing](https://en.wikipedia.org/wiki/Cuckoo_hashing), where we try a second possible row. While this seemed 
promising, simulations show it only increases the fill-level from ~90% to ~94% and comes with a cost of two lookups 
every time a key is not found, so the benefits are unclear.

## No Journal No Cry

<img src="/static/res/2024-08-22-news.png" title="Journal" class="blog-post-image">

In order to utilize SIMD lookups and atomic operations, shard files `mmap` their header table into memory.
Since the header is file-backed, the kernel is free to evict these pages when needed, but hopefully this won't be
the case as this data is accessed frequently and randomly. In terms of overhead, the header table requires 384KB 
and spans ~30K entries, which means it adds an overhead of ~13 bytes per entry. Pretty low for allowing O(1) lookups!

But what about atomicity? Well, atomicity comes in many flavors - we mainly care about consistency, as each key
is independent of each other. This means we want to be able to crash at any point and be able to read the data 
without replaying a journal or a WAL. Losing any currently ongoing operations is considerd okay. By the way, we're not
interested in snapshots or transactions, so that's not supported.

To achieve this, the algorithm always writes entries (be it new ones of updated ones) at the end of the shard file, 
and then proceeds to update the offset and length in the header table (atomically). This means that crashing while 
writing would leak some space, but will not produce an invalid entry: we will always be able to read a valid version
of it of the store. The same goes for removal - it atomically clears the signature from the row, no tombstones are 
needed.

We trust the kernel to flush the `mmap`'ed header table to disk on crashes. In general, we trust the kernel's 
page-cache to take care of read-ahead where needed, flush data periodically, and generally amortize writes. 
A reboot could therefore bring us to an inconsistent state, but the alternative would be to flush the page cache 
when "important things" happen or use `O_DIRECT` to skip the page cache altogether.

## Zero Overhead

<img src="/static/res/2024-08-15-over9000.png" title="Over 9000" class="blog-post-image">

Any persistent data structure is, by definition, limited by the underlying storage. With an NVMe drive, you 
can expect a latency of 20us-100us, so the question then becomes how many IOs are needed per operation, and how 
expensive are your algorithm's computational needs. For instance, sorting a large buffer is a costly operation.

For lookups and removals, CandyStore has an overhead of less than 1us (basically a single `read` syscall), 
and for inserts it's less than 2us (a `read` plus a `write`). If the data needs to be fetched from the disk, 
rather than the page-cache, you can expect a couple of tens of microseconds on top of that, of course, but generally
speaking, this is as fast as it could get.

## Roadmap
* Background compactions
* Generations for TTL and compression
* Consistent-hash on top for a distributed protocol

