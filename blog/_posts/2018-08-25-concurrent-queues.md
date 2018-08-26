---
layout: blogpost
title: "Rethinking Concurrent Queues"
description: "Designing a simple and fast multi-producer-multi-consumer queue"
imageurl: http://tomerfiliba.com/static/res/2018-08-25-producer.jpg
imagetitle: "A single producer"
---

There are many, many implementations of Multi-Producers Single-Consumer/Multi-Consumers Single-Producer [queues](https://en.wikipedia.org/wiki/Producer%E2%80%93consumer_problem) out there... and they all tend to be [very complex](https://github.com/facebook/folly/blob/master/folly/concurrency/UnboundedQueue.h), very long (many different edge cases) and and very *fragile* (reordering innocent-looking lines will likely lead to deadlocks).

Implementing such a queue using a mutex or a semaphore is *quite* trivial, but making it [lock free](https://en.wikipedia.org/wiki/Non-blocking_algorithm) is a whole other story. Such implementations usually rely on atomic-operations and other fine-grained memory-ordering primitives, memory fences, and might make assumptions on the thread's affinity to a certain logical core, among other things. In the bottom line, they have to intimately understand inter-processor communication, and nobody enjoys that kind of intimacy.

I was pondering about this problem a week ago, with the aim of making a simple to understand and robust queue. I started sketching something that later grew into what I *suppose* is the fastest possible such queue -- readers are welcome to make suggestions or point out anything I missed -- but we'll have to discuss some *terms and conditions* beforehand.

## Premises ##

First of all, what is a queue? Most people, I assume, consider it to be a FIFO data structure. But come to think of it, it's quite hard to talk about a *well-defined order* when multiple producers push items concurrently. The order of items in the queue is a *random* order, based on which thread was able to compare-and-swap before the others, so consuming the results *in that particular order* is quite meaningless. The same goes for multiple consumers -- suppose a single producer enqueued `1, 2, 3, 4, 5, 6`; one of the consumers pulled `1, 3, 4`. It is true the items are monotonically-increasing, from the consumer's point of view, but *which items* it picked is totally random, so it's impossible to make any assumptions about the *relative order* of items being pulled by different threads. The fact thread A pulled item `4` does not mean item `2` has begun processing in thread B, since thread B may have been preempted and will only get to run after thread A wraps up. Therefore, the *order of the items in the queue* is meaningless in this case just as well. The only guarantee we get from the queue is that any pushed item will eventually be picked by a consumer: no item may be dropped or overwritten when the queue gets full, and no item may be left behind ("starved") for too long.

It may very well be that some algorithms rely on the monotonicity that I demonstrated above, or that they do need some guarantees about the order of pushing and popping items from the queue -- the design I describe here will not apply to these use cases, at least not without modification.

Second, we need to discuss the nature of the *items* in the queue. Many queues are *templated* on an arbitrary item-type, which may very well be quite big. I claim an `intptr_t/void*` is all you ever need to push and pop. In the case of multiple threads, which all share the same address space, you can simply pass pointers to objects. In the case of multiple processes, which have different address spaces, you can pass indices to an array of elements/offsets into a shared-memory arena. This observation is important since it allows us to work in 8-byte-aligned QWORDs, which are inherently atomic (at least on x86-64).

Third, we'll need an invalid value. A natural such value is `null` if we're talking about `void*` items, or maybe `MAP_FAILED` (which is `(void*)-1`); it doesn't really matter. Since we're using pointers/indices/offsets and not arbitrary data types, we can safely sacrifice one value from the 64-bit range.

## A Simple Queue ##

Now we can get to designing the queue. In fact, it gets so simple we'll start with a Multi-Consumer Multi-Producer queue, the MPSC/MCSP cases being just degenrates cases of it. We'll hold a read-index and a write-index, as well as two counters: number of pushed items and number of popped items. All of these counters are atomically-incremented for simplicity and reducing contention: instead of holding a counter of the number of enqueued items, we can just calculate `numPushed - numPopped` (eventually-consistent), and reduce contention between conumsers and producers.

Pushing an item is done optimisically -- increment the write index and try to compare-and-swap the slot at `writeIndex % N` with the new value, if the current value is `invalid` (empty). If the compare-and-swap fails, repeat; otherwise increment `numPushed` and return. Popping is very similar: first increment the read index and try to atomically exchange the value at `readIndex % N` with `invalid`. If the previous value was not `invalid`, increment `numPopped` and return that previous value; otherwise repeat. And since we don't want to block when popping from an empty queue, we'll only try to pop if `numPushed > numPopped`.

Here's a sketch:

{% highlight d %}
struct ConcurrentQueue(size_t N) {
    enum ulong invalid = -1;

    shared ulong readIdx, writeIdx;                 // `shared` means operated on by atomicOp
    shared ulong numPushed, numPopped;
    shared ulong[N] arr = invalid;

    void push(ulong val) {
        while (true) {
            auto idx = atomicOp!"+="(writeIdx, 1);  // atomically writeIdx++
            if (cas(&arr[idx % N], invalid, val)) {
                atomicOp!"+="(numPushed, 1);        // atomically numPushed++
                break;
            }
        }
    }

    ulong pop() {
        while (numPushed > numPopped) {
            auto idx = atomicOp!"+="(readIdx, 1);   // atomically readIdx++
            ulong res = xchg(&arr[idx % N], invalid);
            if (res != invalid) {
                atomicOp!"+="(numPopped, 1);        // atomically numPopped++
                return res;
            }
        }
        return invalid;
    }
}
{% endhighlight %}

## Correctness ##

This is D code, I hope it's readable by any C/C++ coder as well (at least as pseudo-code). Let's do an informal analysis of the algorithm: it's quite obvious it can't deadlock, since pushing will scan the whole array until an empty slot is found. The same goes for popping, which will iterate until a non-empty slot is found. The `numPushed > numPopped` condition of `pop()` is *eventually-consistent*, so a pop() right after a push might return `invalid`, but *eventually* calling `pop` would succeed. We will never override non-empty slots, so we will never drop items or overwrite unconsumed ones, and since popping scans sequentially, we'll never neglect an item in the queue (an item can't stay in the queue for more than a whole round, i.e., `N` pops).

The only location we're synchronizing on is the array slots themselves, which are 8-byte aligned and 8-byte in size -- we either compare-and-swap or do an uncondition swap (`xchg`). The read/write index we get are "not important" for the correctness -- we don't even have to increment them atomically. If we hadn't, we might repeat the same index several times, but the compare-and-swap protects us. Making it atomic is an optimization, actually. The last bit we're relying on is incrementing `numPushed` and `numPopped`, and these have to be atomic or we'd lose track of the number of items queued, and `pop` will fail. But if we allowed pop to block on an empty queue (or make a whole round before giving up), we wouldn't need these either.

## Efficiency ##

The algorithm is indeed very simple, and *correct* (as far as I can tell), but it may seems highly inefficient as it might scan the whole array each time before finding a slot. First of all, the queue's size is expected to be "big enough" to prevent stalls (i.e., at least double the expected number of queued items). It's a good rule of thumb in any implementation I've checked. To further talk about efficiency, let's discuss two cases -- a sparse queue and a full queue.

As long as the queue is "sparse" (meaning it hadn't filled up and conusumers are on par with producers), `writeIndex < readIndex + N` holds (*), so producers push sequentially (modulo N) so that no gaps are created. When there are no gaps, consumers will pop items one after another and will never need to skip slots. In this case the queue is as efficient as the standard implementations, and even preserves order. (*) There is a caveat here, since the consumer will first increment the read index, and only then swap; if the thread context-switches between the two instructions, the condition above may no longer hold, but producers will not be able to use that slot until it's freed.

Things get complicated when the queue fills up. Again, this is something you'd want to avoid anyway. In this case producers will block, incrementing the write index until they find an empty slot. This may cause `writeIndex > readIndex+N`, so gaps may occur. For example, suppose an 8 element queue is full like so `[10, 20, 30, 40, 50, 60, 70, 80]; N=8, readIndex=0, writeIndex=8`, and two producers are racing to push, idling until the there's room, bringing `writeIndex` to 698 in the process. Now the two producers are preempted, and a consumer thread pops 5 items. Now the consumer is preemted, and the queue looks like so: `[E, E, E, E, E, 60, 70, 80], readIndex=5, writeIndex=698`. One of the producers gets to run, it first increments the write index to 699, `699 % 8 = 3`, so it will try to `arr[3]`. This slot is empty, and it occupies it. Once the consumer wraps around, it will have to skip 3 empty slots before finding an item. But this is only true if the slots remain empty... in the meantime, other producers may be able to find and use them, so by the time the consumer gets around it will not need to skip.

So gaps may only occur when producers outrun consumers, but then again, the same producers will find the gaps *before* consumers will, and fill them up. It is very unlikely for a consumer to find *many* gaps in such cases. Pathological cases may exist of course, but even then it's only a performance penalty, not a deadlock.

## Reducing Contention ##

So this nifty algorithm is great, but any queue that uses read and write indices inherently creates memory hotspots: the indices themselves and the queue's write-head and read-tail. These cache-lines are tossed around different threads (cores) every time an *attempt* to push or pop is made, which leads to heavy contention. The penalty of this gets considerably worse when multiple NUMA nodes are present, as the cost of invalidating cache lines all the time is much higher.

My tests proved, as expected, that memory contention is by far the dominating factor, so I made it a goal to minimize it. Since the problem is inherent to having a shared head and tail, it is clear we must let go of them. The solution I came up with is rather trivial -- spread the producers and consumers all over the array, and have each work with a local set of indices.

