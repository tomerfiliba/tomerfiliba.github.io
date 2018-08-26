---
layout: blogpost
title: "Probably the Fastest Concurrent Queue in the World"
description: "Rethinking multi-producer-multi-consumer queues"
imageurl: http://tomerfiliba.com/static/res/2018-08-25-producer.jpg
imagetitle: "A single producer"
---

There are many, many implementations of Multi-Producers Single-Consumer/Multi-Consumers Single-Producer [queues](https://en.wikipedia.org/wiki/Producer%E2%80%93consumer_problem) out there... and they all tend to be [very complex](https://github.com/facebook/folly/blob/master/folly/concurrency/UnboundedQueue.h), very long (handling different edge cases) and and very *fragile* (reordering innocent-looking lines will likely lead to deadlocks).

Implementing such a queue using a mutex or a semaphore is *quite* trivial, but making it [lock free](https://en.wikipedia.org/wiki/Non-blocking_algorithm) is a whole other story. Such implementations usually rely on bus-locking and other fine-grained memory-ordering primitives and memory-fences to force cache invalidation, and might make assumptions on the thread's affinity to a certain logical core, among other things. In the bottom line, they have to intimately understand inter-processor communication, and nobody enjoys that kind of intimacy.

I was pondering about this problem a week ago when I started sketching something that later grew into what I *suppose* is the fastest possible such queue -- readers are welcome to make suggestions or point out bugs -- but we'll have to discuss some *terms and conditions* beforehand.

First of all, what is a queue? Most people, I assume, consider it to be a FIFO data structure. But come to think of it, it's quite hard to talk about a *well-defined order* when multiple producers push items concurrently. The order of items in the queue is a "best-effort order", based on which thread was able to compare-and-swap before the others, so consuming the results *in that particular order* is quite meaningless. The same goes for multiple consumers -- suppose a single producer enqueued `1, 2, 3, 4, 5, 6`; one of the consumers pulled `1, 3, 4`. It is true the items are monotonically-increasing, from the consumer's point of view, but *which items* it picked is totally random, so it's impossible to make any assumptions about the *relative order* of items being pulled by different threads. The fact thread A pulled item `4` does not mean item `2` has begun executing in thread B, since thread B may have been preempted and will only ever run after thread A wraps up. Therefore, the *order of the items in the queue* is meaningless in this case just as well. The only guarantee we get from the queue is that any pushed item will eventually be picked by a consumer: no item will be dropped or overwritten when the queue gets full.

It may very well be that some algorithms rely on the monotonicity that I demonstrated above, or that they do need some guarantees about the order of pushing/popping items from the queue -- in that case the queue I describe here is not useful, at least not in it's current form.

Second, we need to discuss the nature of the *items* in the queue. Many queues are templated on an arbitrary item-type, which may very well be quite big. I claim `intptr_t/void*` is all you ever need to push and pop. In the case of multiple threads, which all share the same address space, you can simply pass a pointers to objects. In the case of multiple processes, which have different address spaces, you can pass indexes to an array of elements/offsets into a shared-memory arena. This observation is important since it allows us to work in 8-byte-aligned QWORDs, which are inherently atomic (at least on x86-64).

Third, we'll need an invalid value. A natural such value is `null` if we're talking about `void*` items, or maybe `MAP_FAILED` (which is `(void*)-1`); it doesn't really matter. Since we're using pointers/indexes/offsets and not arbitrary data types, we can safely sacrifice one value from the 64-bit range for an invalid element.

Now we can get to designing the queue. In fact, it gets so simple we'll start with a Multi-Consumer Multi-Producer queue, the MPSC/MCSP cases being just degenrates cases of it. We'll hold a read-index and a write-index, as well as two counters: number of pushed items and number of popped items. All of these counters are atomically-incremented for simplicity and reducing contention; for example, instead of holding a counter of the number of enqueued items, we can just calculate `numPushed - numPopped`.

Pushing an item is done optimisically -- just increment the write index and try to compare-and-swap the item at `writeIndex % N` with the new value, if the current value is `invalid`. If the compare-and-swap fails, repeat; otherwise increment `numPushed` and return. Popping is very similar: first increment the read index and try to atomically exchange the value at `readIndex % N` with `invalid`. If the previous value was not `invalid`, increment `numPopped` and return that previous value; otherwise repeat. And since we don't want to block when popping from an empty queue, we'll only try to pop if `numPushed > numPopped`.

Here's a sketch:

{% highlight d %}
struct ConcurrentQueue(size_t N) {
    enum ulong invalid = -1;

    shared ulong readIdx, writeIdx;
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

This is D code, I hope it's readable by any C/C++ coder as well (at least as pseudo-code). Let's analyze the algorithm a bit: it's quite obvious it can't deadlock, since pushing will iterate the whole array until an empty slot is found. The same goes for popping, which will iterate until a non-empty slot is found. The `numPushed > numPopped` condition of `pop()` is eventually-consistent, so a pop() right after a push might return `invalid`, but "eventually" calling `pop` would succeed. We will never override non-null items, so we will never drop items or overwrite unconsumed ones, and since popping iterates sequentially, we'll never neglect an item in the queue.

I believe this informal explanation is good enough to show the algorithm is *correct*, but it may seems inefficient as it might scan the whole array each time before finding a slot. First of all, for efficiency, the queue's size must be "big enough" to prevent stalls (i.e., at least double the expected number of queued items). To further talk about efficiency, we'll examine the more common use-cases of single-producer and single-consumer:

* In the single-consumer case, items are pushed *contiguously* (modulo N) by multiple producers; once the consumer finds the first non-empty slot, it will continue to "hit" non-empty slots until it consumes them all. There are no gaps, so the consumers will never "circle around" to find a single element. The producers may have a harder time -- when the queue gets full

In the single-producer case

My experimentation showed, as expected, that memory contention between cores (especially given multiple NUMA nodes) is the dominating factor by far, so I made it a goal to minimize it. Suppose


