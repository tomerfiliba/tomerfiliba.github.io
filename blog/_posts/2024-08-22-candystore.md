---
layout: blogpost
title: A Sweet Key-Value Store
description: "CandyStore - a fast and efficient key-value store in pure Rust"
imageurl: /static/res/2024-08-15-candystore.jpeg
imagetitle: "Tasty bytes!"
---

## TL;DR
*Sweet Security* has just released [CandyStore](https://github.com/sweet-security/candystore) - a **very fast Key-Value 
Store** in Rust with negligible memory overhead and unique features like lists and queues. 
The library is meant to be used an *embedded database*, but in the future we may release a server and C bindings.
It's based on a novel algorithm, not one based on LSMs or B-Trees, and does not require any journal/WAL while still 
being atomic and crash-safe.

## Life, the Universe and Everything

Well, it's been ten years since I've felt like I have something interesting to share with the world. A short recap
of these years would reveal me having two kids (the eldest being 10 y/o... I wonder if it has anything to do
with it?). I've had my fun time in the storage industry at [Weka](http://weka.io), where I've done everything from 
developing a super low-latency scheduler and inventing a network protocol, all the way to large-scale distributed 
algorithms. I've also had a taste of corporate life at ~~Facebook~~Meta and learned that it's not for me (*surprise surprise*). 

<img src="/static/res/2024-08-15-cyber.jpg" title="Cyberaliens" class="blog-post-image">

Nowadays I'm the CTO of [Sweet Security](https://sweet.security/) - we offer a whole *suite* of Cloud Security based 
on *Runtime* data, and offer Detection & Response, Vulnerability Management, Non-Human Identities management, and more. 
Amazing technology and people, for sure, but we're not here to talk about cyber security... we're here to 
*talk about storage?!*

You see, we develop a very lean sensor (in Rust) that runs on customers' workloads. Low resource consumption is of 
the essence, because production environments are not as forgiving as employees' laptops (think antivirus/EDR). 
In order to free some memory for more features to come, we had to move some of the state we keep in hash tables 
and lists to disk. Surely the answer is to take some battle-tested embedded database/key-value store (a DB that runs 
inside your app), such as `sqlite` or `rocksdb`, and keep our data there. Right?

## On LSMs, B-Trees and Locking 

<img src="/static/res/2024-08-15-wal.png" title="O(1)" class="blog-post-image">

The short answer: we've tried ~5 mainstream and well-known embedded database and they all failed us. Some had bad 
perofmance, some had huge memory demands and some had inconsistent pefromance and deadlocks. We have multiple 
threads accessing data, or iterating while deleteing elements, and the DB must support such usage patterns.

In general, databases are either based on *B-Trees* (like binary search trees with "wider nodes") or 
*Log-Structured Merge (LSM)* trees, and most databases (if not all) require a *journal* or a *Write-Ahead Log (WAL)*. 
B-Trees are the de-facto standard way to implement indexing: they allow for cheap range queries. We specifically 
have no need for range queries, and in practice all B-Tree based databases tend to perform more slowly than ones 
based on LSMs. 

LSMs dominate the key-value store world, as they're optimized for write intensive workloads, and the principle 
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
pointer-chasing on collisions. These two constraints basically require keeping everything in-memory and the idea
of keeping a hash table in a file would have people questioning your sanity. So let's do it!

## Welcome to the CandyStore

Taking this idea a bit further brings us to [CandyStore](https://github.com/sweet-security/candystore): **a zero-overhead
extension of hash tables onto files**. It is a part-tree-part-hash chimera, taking advantage of the uniform
distribution of hashes in three ways: a 64-bit hash value is split into 16 bits of *shard selector*, 16 bits of 
*row selector* and a *signature* of 32 bits.

<img src="/static/res/2024-08-22-candy.png" title="Sweet" class="blog-post-image">

The main concept is the `ShardFile`: it contains of all entries that have a certain hash prefix. In order to keep
resource comsumption minimal, CandyStore starts with just a single shard file covering the whole shard range, so in 
our case `[0-65536)`. Each shard file has a header table, made of rows, and each row is made of signatures. 
Immediately following the header table is the entries' data.

After reaching the correct shard file and row, using the selectors taken from the hash, we perform a parallel 
lookup (using SIMD instructions) over all of the signatures, finding the one we're looking for very quickly. 
The header table also contains the entry's file offset and length, so once found, we can go ahead of read it 
directly from the file.

With the default numbers of 64 rows per shard file, each with 512 signatures, a shard file is expect to hold ~30K 
entries (utilization of 90%). The chance of collisions (i.e., two different keys having the same signature) within 
a single row are 0.003%, which means the probability we fetch the correct entry from the file is practically 100%. 
Since in persistent storage algoritms we care mostly about disk access, it means we have a `O(1)` way of fetching a 
key from the store.

What happens when a shard file becomes full? If a certain row reaches its limit of 512 signatures, we split the entire
shard file into a bottom half and a top half: we basically take into consideration one more bit from the shard 
selector. Initially, we started with a shard file covering the shard range `[0..65536)`, and we end up with
one shard file covering `[0..32768)` and the other shard file covering `[32768..65536)`. Now every entry whose MSB 
is 0 goes to the bottom shard, and every entry with an MSB of 1 goes to the top shard. Assuming hashes are uniformly
distributed, each shard will contain half of the entries of the original one, and we can rest assured the resulting 
shard-file tree will be *balanced*, as we can expect the tree to be [complete](https://en.wikipedia.org/wiki/Binary_tree#Types_of_binary_trees).

Note that it's possible to increase the efficiency using a method similar to 
[Cuckoo hashing](https://en.wikipedia.org/wiki/Cuckoo_hashing), where we try a second possible row. While this seemed 
promising, simulations show it only increases the fill-level from ~90% to ~94% and comes with a cost of two lookups 
every time a key is not found, so the benefits are unclear.

## No Journal No Cry

<img src="/static/res/2024-08-22-news.png" title="Journal" class="blog-post-image">

In order to utilize SIMD lookups and atomic operations, shard files `mmap` their header table into memory.
This header is file-backed, so the kernel is free to evict these pages when needed, but hopefully this won't be
the case as this data is accessed frequently and randomly. In terms of overhead, the header table requires 384KB 
and spans ~30K entries, which means it adds an overhead of ~13 bytes per entry. Pretty low for allowing `O(1)` lookups!

But what about atomicity? Well, atomicity comes in many flavors - we mainly care about single-key consistency, 
as keys are independent of each other. This means we want to be able to crash at any point and be able to read the data 
without replaying a journal/WAL. Losing any currently ongoing operations is considerd okay. By the way, we're not
interested in snapshots (although it's possible to implement) or transactions (impossible without a journal), 
so that's not supported.

To achieve this, the algorithm always writes entries (be it new ones or updated ones) at the end of the shard file, 
and then proceeds to update the offset and length in the header table (atomically). This means that crashing while 
writing would leak some space, but will not produce an invalid entry: we will always be able to read a valid version
of it of the store. The same goes for removal - it atomically clears the signature from the row, no tombstones are 
needed.

We trust the kernel to flush the `mmap`'ed header table to disk on crashes. In general, we trust the kernel's 
page-cache to take care of read-ahead where needed, flush data periodically, and generally amortize writes. 
A reboot could therefore bring us to an inconsistent state, but the alternative would be to flush the page cache 
when "important things" happen or use `O_DIRECT` to skip the page cache altogether. That would be bad for performance,
and it's a risk we're taking.

## Zero Overhead

<img src="/static/res/2024-08-15-over9000.png" title="Over 9000" class="blog-post-image">

Any persistent data structure is, by definition, limited by the underlying storage. With an NVMe drive, you 
can expect a latency of 20us-100us, so the question then becomes how many IOs are needed per operation, and how 
expensive are your algorithm's computational needs. For instance, sorting a large buffer is a costly operation.

For lookups and removals, CandyStore has an overhead of less than 1us (basically a single `read` syscall), 
and for inserts it's less than 2us (a possible `read` plus a `write`). If the data needs to be fetched from the disk, 
rather than the page-cache, you can expect a couple of tens of microseconds on top of that, of course, but generally
speaking, this is as fast as it could get given you minimize RAM usage.

## Lists and Queues
As mentioned above, hash tables are great so long as you don't require relative order or prefix search. Instead of
imposing a relative order on keys, CandyStore provies a linked-list-like structure. You can add an item to a *list*, 
and it gets pushed to the list's tail. You can lookup/update/remove the item in `O(1)` time, just like any key, 
but you can also iterate over the items in list in `O(n)`.

On top of lists, CandyStore also provides *queues* (or actually, *deques*), where you push elements to the head
or the tail of the queue, and pop elements from either side as well. 

## Roadmap
CandyStore is deployed on thousands of nodes in production (part of Sweet's sensor) and we offload more and more
use cases from in-memory tables or queues to disk-based ones. 

That being said, it's important to understand that CandyStore is **very new** -- less than a month old at the 
time of this writing! The **file format is unstable**, and for our use cases, we're happy with just clearing the 
DB and starting over. 

One thing that we work on is background (non-blocking) compactions, so compations won't block access of the 
shard file as they do now. We keep the files relatively small (~20MB), so compaction is a short operation, but that's
work in progress.

We might add TTL support later on, in the form of *generations*, inspired by LSMs. Since entries that survive
for long are less likely to be modified or removed, we can also compress older generation shards. TTL can be 
efficiently implemented on top of generational shards, as we can simply delete the delete entire generation as it ages.

It's also possible to use a protocol like Cassandra's, where we take some more bits from the hash and use them
in a consistent hash construction to determine which nodes are in charge of these keys. To that we could add
*replication factor* and *consistency level* for redundancy, in the same way Cassandra does, but there are also
alternatives.

Anyhow, who said cyber security is not deep-tech?
