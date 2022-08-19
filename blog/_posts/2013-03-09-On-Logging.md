---
layout: blogpost
title: "Javaism, Exceptions, and Logging: Part 3"
draft: true
description: "Javaism, Exceptions and Logging: Lessons from refactoring large codebases. Part 3 of 3"
imageurl: /static/res/2013-03-10-solkin_logging.jpg
imagetitle: Over-logging
---

Yes, it's been a while. This is the third (and last) installment of my series on "Javaism, Exceptions and Logging",
in which I criticize non-Pythonisms creeping into Python from other OO languages, most prominent on which is Java.
The first part introduced the "Java problem" (*in Python we can do better*), the second part tackled exceptions
(*never hide exceptions, don't wrap exceptions, and in fact, don't handle exceptions*), and the third part
covers lesson I've learned from logging in large-scale Python library (*less is more*).

> * [Part 1: Javaism](/blog/Javaism)
> * [Part 2: On Exceptions](/blog/On-Exceptions)

## Less is More ##

When working on large, complex projects, people are often tempted to log everything they do; they want to "keep
record" of everything for harsh times. While logically, you'd want to know as much as you can when debugging
a hellish error -- over-logging is a sure path to shooting yourself's in the foot.

First, and although it's usually not a problem - **logs hurt performance**. Yes, I know the drill about premature
optimizations, but keep in mind that adding *several* system calls (get time, acquire mutex, write to FD, ...) too
often will have a toll on your performance. This becomes especially important if your code is CPU-bound: logs are
usually written to HDDs, so if you're not careful, you might limit your throughput by that of your mechanical disk!

But the true problem of over-logging usually only encountered later on, when it's time to get your hands dirty
and solve nasty bugs. Querying huge logs is slower, of course, so your ``grep``ing might be impractical. If fact,
I've seen places where the logs were so full of sh*t that nobody even tried to look at them! They just gave up.
Also, sending home logs in the magnitude of 10's of GB from a customer's site is normally infeasible, which means
your boss has to put a technician (or you!) on a plane.

Lastly, logs rotate (every hour/day/week/so many MB, etc.), so you have to calibrate the frequency of logging and
log-rotation with the expected history you'd require, or you'd lose the valuable information that you hoped to keep.

In other words, **log as little as possible**, or **log only interesting information**. There's no point in keeping
track of things you won't need.

## What Goes Where ##

As logs go hand in hand with "bad things", I'm particularly interested in the *intersection of logs and exceptions*.
Many times I've seen code like this:

{% highlight python %}
try:
    myfunc()
except Exception:
    logger.error("something went wrong", exc_info = True)
    raise
{% endhighlight %}

What's the use in this? You haven't *handled* the error -- you just added noise to the system! Functions higher up
the stack then follow the same pattern - they catch an error, log it and (hopefully) re-raise it, so you end up
with the same exception being duplicated all over the place. And sometimes (and this really drives me nuts), people
raise rather-generic exceptions telling you to see the log! WTF?!

Exceptions should (optimally) be self-contained, holding all of the relevant information about the error. Don't make
your life harder by putting half of the information in the log and the other half in the exception object.

As a rule of thumb, libraries should never log exceptions - they should let the propagate up with as much information
about them as possible. Applications that have human-users (or unsupervised ones, like web servers) should only log
exceptions at the outermost exception handler, before they reach the end user or are lost for good. Logs are not meant
to be dumpsters for exception, they are meant to tell you the *history* of your application so that exception +
logs = whole story.

## The Or-er-or Pattern ##

Some years ago, a friend of mine coined the derogatory term *or-er-or*, which refers to all design-patterns that
"end with -or or -er", such as *Adapter* and *Delegator*. He claimed that all of these are good-for-nothing,
over-engineered layers of abstractions that add no real power and only serve to boost one's ego. He wasn't referring
to Java in particular (although Java is clearly fond of these), and I can't say I fully agree with this claim,
but I think he captured a nice generalization here.

In the first installment, I had an argument with Vinay Sajip concerning Python's ``logging`` module. I said it's a
clear case of copy-from-Java, and Vinay said that while it "borrows" from [log4j](http://en.wikipedia.org/wiki/Log4j),
it makes *easy tasks simple and hard tasks possible*. Let's face it - *how hard can logging ever get*? It's a
question of software engineering and style, not ``P=NP``, and I think ``logging`` manages to make easy and hard
tasks equally as hard.

Here goes nothing: pop up an interpreter, import ``logging`` and type ``help(logging)``. Here's the class diagram
you'll see:

    CLASSES
        __builtin__.object
            BufferingFormatter
            Filter
            Formatter
            LogRecord
            LoggerAdapter
        Filterer(__builtin__.object)
            Handler
                NullHandler
                StreamHandler
                    FileHandler
            Logger

``Filterer``?! Can it get more or-er-or than that?

## On an Unrelated Note ##

Be sure to [stop writing classes](http://pyvideo.org/video/880/stop-writing-classes). That's another Javaism.
