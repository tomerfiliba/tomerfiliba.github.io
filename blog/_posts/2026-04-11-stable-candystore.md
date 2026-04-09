---
layout: blogpost
title: "A Stable CandyStore"
description: "Consistency, crash resiliency and a stable file format in an O(1) key-value store!"
imageurl: /static/res/2026-04-09-candy-v1.png
imagetitle: "A stable candy"
---

## TL;DR

Note: here is [Part 1](/blog/candystore) and [Part 2](/blog/consistent-candystore)

[CandyStore](https://github.com/sweet-security/candystore) has reached **v1.0** -- the O(1) key-value store 
now has true crash consistency, a stable file format, and an overall simpler design. If you haven't read the 
previous posts, CandyStore is a pure-Rust, embedded key-value store that relies on hash-based indexing to achieve 
O(1) lookups, inserts and removals with negligible memory overhead. It was built at 
[Sweet Security](https://sweet.security/) where we needed to offload in-memory state to disk without paying the 
price of LSMs, B-Trees or WALs.

Since the [initial release](/blog/candystore) and the [discussion that followed](/blog/consistent-candystore), 
two themes kept haunting me: machine-crash consistency and the file format. Both are now addressed properly, and 
I want to walk you through the changes.

## How It Works

CandyStore extends a hash table onto files: a 64-bit hash is broken into a *row selector* and a *signature*.
The row selector locates a row in an mmap'ed index table, and the signature is looked up within that row using 
SIMD instructions. Which bits of the row selector are considered meaningful depends on the current *split level*.
Entries are *appended* to data files, and the index stores compact pointers into them. No WAL, no journal, 
no sorting, no merging. Just a hash table on disk.

Writes are equally simple: append the new entry to the active data file, then atomically update the index to point 
at it. If this is an update, the old entry just becomes garbage to be cleaned up later. Removals append a tombstone
and then update the index. That is really the whole trick: the data files are append-only and serve both as a journal
and as the live data structure, while the index is a compact, rebuildable view over them.

This is also why negative lookups are so fast: most of the time we can decide the key is absent just by scanning 
the signatures in the row, without touching the data file at all.

<img src="/static/res/2026-04-09-algo.png" title="Single index, multiple data files" class="blog-post-image">

The nice part is that the algorithm stays O(1) even as the store grows. Rows split individually, data files rotate,
and compaction happens in the background. So the interesting question for v1.0 was not really how to make Candy 
faster -- it was already 1-2 syscalls per key -- it was how to make this whole thing recover cleanly after the 
machine itself goes sideways.

In the first version, process crashes were generally fine: data was append-only, the index was mmap'ed, and we 
would trust the operating system to eventually flush things out. But a power failure or kernel panic could still 
leave the index in an unknown state relative to the data files, which we couldn't even detect. In the 
[second post](/blog/consistent-candystore) I sketched out a journal-block scheme to address this. The actual 
solution turned out to be simpler and more elegant.

## Row-Based Splits

In the original design I described shard files that split when full. The v1.0 design simplifies this: there's 
a single index with rows, and when a row reaches its limit of 336 entries, *that row* splits. We bump the row's 
split level by one, taking an extra bit into account for the row selector. Each row splits into two children, 
and because hashes are uniformly distributed, roughly half the entries migrate.

The split itself is crash-safe in three phases: (1) copy eligible entries to the new high row, (2) publish the 
high row, (3) publish the low row and clean up. If we crash mid-split, the worst case is some phantom entries 
that get cleaned up on rebuild. No data is lost.

<img src="/static/res/2026-04-09-split.png" title="Row splitting" class="blog-post-image">

This also means splitting is O(1) -- we only touch one row's worth of entries, not the whole table, 
and it's all memory-bound. The mmap *may* need to grow (doubling the table size), but that's mostly page-table 
work and amortizes to O(1). There's never a full rehash.

## Non-Blocking Compaction

Since data files are append-only, updates and deletions accumulate waste. The compaction worker runs in the 
background, iterates over the rows table (so it's also memory bound) to find entries that point to files worth 
compacting (based on waste ratio), and rewrites them to the active data file. Once all living entries have been
migrated out of an old file, it's simply deleted.

Compaction is rate-limited using a **token-bucket pacer** -- you configure the throughput in bytes per second. 
This prevents compaction from saturating your disk and starving actual read/write operations. A sane default is 
provided, but you can tune it based on your workload and storage.

## Checkpointing

That brings us to the part that used to be missing. Instead of a journal, v1.0 introduces **background 
checkpointing**. A background worker periodically snapshots a *consistent view* of the index and persists it. 
There are two triggers -- a time-based interval (defaults to 5 seconds) and a data-volume threshold (defaults 
to 128KB of modifications). Whichever comes first kicks off a checkpoint.

The index header holds two checkpoint slots (double-buffered) with checksums, so we always have a known-good 
fallback. Candy also tracks in-flight writes per row so each checkpoint records a restart point that is known to be 
internally consistent. This is all asynchronous; writers are never blocked by checkpoint activity.

Why not the journal-block scheme I described in the previous post? Well, it turns out that separating the *source 
of truth* (append-only data files) from the *index* (a rebuildable acceleration structure) is a much cleaner 
design. The data files are always consistent because they're append-only and we never overwrite. The index is just 
a materialized view of the data. If the index is compromised, we throw it away and rebuild.

## Rebuild: The Safety Net

On startup, Candy validates the checkpoint. If everything checks out, it replays only the mutations that happened 
*after* the last successful checkpoint -- a very short tail of the data files. This is the fast path: most of the 
index is already valid, and we just catch up.

If the checkpoint is corrupted, or if the index version doesn't match (more on that later), Candy falls back to 
a **full rebuild**: it reads the append-only data files from the beginning and reconstructs the entire index. 
This is obviously slower, but it's a one-time cost on an unclean startup. And because we checkpoint incrementally 
during the rebuild itself, even a crash *during* rebuild is resume-safe.

The rebuild also handles edge cases like truncated files, phantom entries from interrupted splits, and torn writes. 
Each entry also carries a small CRC16 trailer, so replay can tell the difference between a valid tail entry and 
garbage left behind by a torn write. On top of that, rebuild validates that each entry belongs to the row it 
claims to, discarding anything that doesn't add up.

## A Stable File Format

One of the goals of v1.0 was to establish a **stable file format**. The append-only data files are the 
compatibility boundary: they carry a magic number and a version that Candy recognizes. The index format may 
still evolve between minor versions, and when Candy opens a store with a recognized data format but an 
outdated index, it simply rebuilds the index from the data files. This is the same rebuild path used for 
crash recovery, so it's well-tested.

Pre-v1.0 stores are not covered by this promise, but going forward, your data survives library upgrades. 
That was one of the explicit non-goals of the initial release (the file format was unstable), and I'm happy 
we got there.

## Performance

On my somewhat-overkill laptop (AMD Ryzen AI MAX+ 395, 32 cores, 64GB RAM) the numbers look like this:

| Operation          | Time      |
|--------------------|-----------|
| Insert             | 0.53us    |
| Update             | 0.63us    |
| Positive Lookup    | 0.31us    |
| Negative Lookup    | 0.05us    |
| Remove             | 0.60us    |

These measure the algorithm's overhead, not the storage layer. If your data is in the page cache (which it 
typically is for hot keys), you pay for a syscall and some pointer chasing. If it's on disk, add 20-100us 
for an SSD round-trip.

Negative lookups deserve special mention: they're blazingly fast because we can determine a key doesn't exist 
purely from the index (SIMD scan of the signatures), without touching the data file at all. The odds of a hash
collision in the current scheme are negligible (about 1 in 20 billion).

## In Short

v1.0 does not mean CandyStore suddenly became a different beast. It is still the same slightly-unhinged idea of
extending a hash table onto files. What changed is that the recovery story is now solid, the on-disk contract is
finally something I can commit to, and the whole thing feels much less like a clever experiment and much more like
a database. Which, I suppose, is what version numbers are for.
