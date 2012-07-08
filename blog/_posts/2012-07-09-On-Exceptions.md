---
layout: blogpost
title: "Javaism, Exceptions, and Logging: Part 2"
description: "Javaism, Exceptions and Logging: Lessons from refactoring large codebases. Part 2 of 3"
draft: true
---

<img src="http://tomerfiliba.com/static/res/2012-07-09-i-fixed2.jpg" class="blog_post_image" title="Nesting Exceptions..." />

Considering the reactions to the [previous post](http://tomerfiliba.com/blog/Javaism) in this 
series, my intent was obviously misunderstood. Please allow me to clarify that **I was not 
attacking Java or Python**: Java is popular and has proven to be productive, 
both as a language and as an ecosystem; the stylistic and semantic choices it makes are none of my 
concerns (although I'm not a big fan). And as for Python, I was saying that it **copied Java's 
implementation** in some modules (and I think I've proved the correlation pretty well). 
I said that it's silly, because **Python is not subject to the same limitations** of Java, 
which dictate how the Java implementation works. I'm not going to open the discussion over 
whether OOP is good or bad, or mix-ins vs. interfaces, etc. -- I'm simply saying that "Java 
concepts" (which I called *Javaisms*) seem to enter Python **for no good reason**. Meaning, in 
Python we have better (more Pythonic) ways to do it. I hope the scope of my discussion is clear now.

## When Life Serves You Lemons ##

In this installment, I'm going to discuss how to **properly work with exceptions**, based on my long 
experience with large-scale Python projects. In fact, this series was born after I got frustrated 
with the code quality of a certain library that my team develops. Naturally I can't include code
snippets here (and there would be too many of them); instead, I wish to share a some 
representative examples that I encountered:

* I used a function in the spirit of ``open_device(devfile)``, and passed a nonexistent device file 
  (for testing purposes or by mistake), say, ``"/dev/nonexistent"``. Knowing how the library works,
  the underlying error surely was ``IOError(ENOENT)``, but what I got back was a troubling 
  ``DeviceDoesNotExistError``.

* I called ``get_device_info()`` and it simply returned ``None``. Digging into the code, it
  turned out this function catches ``DeviceError`` and returns ``None``. Further investigation 
  showed that my machine had a more recent version of a dependency installed on it, where some 
  method's name had changed. At some point (deep into the stack), the code used ``except 
  Exception`` (which, of course, caught this ``AttributeError``) and translated it into a 
  ``DeviceError``.

* I called a function such as ``enumerate_all_devices()`` and it returned an empty list.
  At first I was told "Of course, this library isn't supposed to work on Ubuntu, only on RHEL". 
  Further (and very tedious) investigation showed it simply needs to run as ``root``. 

This kind of stuff happens to me every time I get to an unexplored corner of the code, I kid you
not. I've already devised a method for debugging such cases: I comment-out all exception handling
code in any function along the way, until I find the actual error -- which is basically the 
treatment that I'm about to suggest here: 

<span style="display: block; width=100%; background: #FFA"> 
The first rule of exception handling is: **Don't handle exceptions**</span>

## Do Not Catch Broadly ##

*Always catch only the most-derived/most-specific exception.* I believe this rule is very obvious
in theory, but harder to follow in practice: the number of exceptions might be large and their 
handling similar; you have to *import* specific exceptions from libraries, which tightly-couples
your code with implementation details; some libraries don't use a common exception base class for
all of their exceptions, which leads to many isolated ``except``-clauses.

All in all, you might have attenuating circumstances, but try to stick to this rule as much 
as possible. On the other hand, **never use an empty** (unconstrained) ``except:``! Such an 
``except``-clause will catch **all exceptions**, including ``SystemExit`` and ``KeyboardInterrupt``. 
So unless you plan to loose the ability to Ctrl-C a running program, or even prevent it from 
terminating gracefully, take the extra step and use ``except Exception``.

## Do Not Be Overprotective ##

A tendency I find in many programmers is being overprotective towards their users, to the points 
where it seems like paternalism. It's as if they try to "take care of everything that might go 
wrong", so the user "won't have to deal with the real world"... sounds childish, I know.

When I pass a filename to a function and that function can't open it for whatever reason, there's 
no need to *mask out* the underlying ``IOError`` in favor of a "user-friendlier" 
``FileDoesNotExistError``, or return ``None`` or ``-1``. As the saying goes, **"we're all 
consenting adults here"**. You should expect your users (programmers) to have sufficient 
background: they don't have to be kernel hackers just to open a file, but they surely should 
know what ``ENOENT`` or ``EPERM`` are (or be able to look them up). Besides, the "raw" 
``IOError`` looks like

    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    IOError: [Errno 2] No such file or directory: '/dev/nonexistent'

and anyone with some common sense would be able to cope with it. 

Put it differently, ask yourself what **useful information** are you adding here? How does a
``FileDoesNotExistError`` help the user (again, a programmer) solve the issue better? You're only 
adding clutter; and you might have dealt with ``ENOENT``, but what about ``EPERM`` or ``EISDIR``?

The error message already includes all the required information and you have nothing meaningful 
to add to that. Instead of treating your user like a baby, just let the raw ``IOError`` 
propagate up.

I must say this phenomena **virtually doesn't exist in open-source code**, but in closed-source 
projects I find it all over the place: I'd guess corporate-employed programmers make the worst 
parents :-)

### A Note On Real Users ###

A question then arises: **what about non-programmer end-users?** What if my product's a GUI/CLI 
and a nasty stack trace suddenly shows up?

Well, first of all, **this rule only deals with libraries** and products whose end users are 
programmers. But on second thought, would your user care if it's ``IOError`` or  
``FileDoesNotExistError``? Just make sure your error message descriptive and easy to understand;
it's much more important.

But then again, when it comes to non-programmers, I don't want to get into generalizations. 
They might as well **not be** consenting adults...

## Do Not Wrap Exceptions ##

Prior to Python 3, raising an exception during the handling of one, meant the original traceback
was lost. This has been finally solved, but Python 2.x still accounts for the majority of the code 
base. Once you loose the traceback, debugging the problem are much harder (especially when it 
happens off-site, on a customer's production server).

Some people think that if they develop FooLibrary, all exceptions that would ever be thrown from
their code must derive from ``FooError``. That's a reasonable approach -- but only when it comes
to exceptions that actually **originate in FooLibrary**. For instance, a queuing library might 
raise ``QueueFull`` or ``QueueEmpty``, both of which derive from ``QueueError``.

On the other hand, should an ``OSError``/``IOError`` happen internally, from which you can't recover, 
**do not wrap it** by a ``FooError``. Recalling the queuing library, if it can't save the queue to 
a file because the file's permissions are wrong or the partition is out of space -- that's **not** 
a ``QueueError``. Your user wouldn't want to ``except QueueError: retry()`` in this case -- he/she 
should be made aware of it and fix the problem.

Likewise, if you're developing an HTTP library, don't wrap ``socket.error(ECONNRESET)`` with
an ``HTTPError``... that's not your library's fault, and it's clearly not an HTTP error. Besides,
there are so many possible errors that might occur (including ``AttributeErrors``) that it simply 
doesn't make sense to wrap all of them.

This rule has a lot in common with the previous one, but the two serve different purposes. In this
case, it originates with Java's checked exceptions: since you won't be able to raise ``IOException``
in a function whose signature specifies only ``HTTPException``, the common practice is to wrap 
the ``IOException`` inside an ``HTTPException``. This is a form of Javaism that is simply not 
necessary in Python and ruins the traceback (again, prior to Python 3).

It only makes sense to wrap an underlying exception by a "higher" one when you can provide more 
information on the source/reason for the error. For instance, if a connection-reset occurred when
the server rejected your SSL certificate, it makes sense to raise ``ServerHungUpOnMe``.
Another reasonable place to wrap exceptions is when to allow retry of some sort. Suppose you're
given a list of endpoints to connect to, and any one of them will do. It might be that the first 
few are down but the last one is up, in which case it would succeed. On the other hand, they might 
all be down; in such a case, I would accumulate all individual errors into a list and raise some 
sort of ``ConnectionError(list_of_individual_errors)``.

Bottom line: **only wrap if you add useful information** to the original exception. If you reraise
it under a different name, don't.

## Do not Handle Exceptions ###

Okay, now you must think I've completely lost it and stopped making any sense: *don't handle
exceptions? WTF?!* Well, let me rephrase that: exceptions should be handled only

* **Where it's possible to fix them** - for instance, suppose you tried ``recv``-ing from a socket and 
  got an ``EINTR`` error, so it makes sense to catch the error (of course, only if it's ``EINTR``)
  and retry. Another example is for fallbacks: suppose you first try to read user-specific 
  configuration (``~/.myconfig``), but if one is not found, you default to a system-wide 
  configuration (``/etc/myconfig``). There are many more cases, of course, but my point is, only
  **handle** an exception if you have **something meaningful** to do about it.
  
* **Where proper cleanup/rollback is required**. You might want to release mutexes and other 
  resources only in case of an exception (regardless of where it has happened). A ``finally``-clause 
  or a [context manager](http://www.python.org/dev/peps/pep-0343/) might do, but many times it 
  makes sense to run the cleanup only in case of an exception; such cases should normally look 
  like so:
  
  {% highligh python %}
  try:
      do_something_that_might_fail()
  except Exception:
      do_cleanup()
      raise
  {% endhighligh %}

* **In the main function** - when all else fails, and you don't wish to crash with a traceback,
  you may catch the exception in the application's ``main`` function. You might want to log it
  to a file, pop an error message on the screen, ask the user what to do next, send an email
  to the webmaster, etc.

In other words: handle an exception only if you're actually handling the exception. It might seem 
obvious, but you'd be surprised how many times I find code that handles exceptions for no good 
reason, and in the process causes much more trouble than it initially had. It's very easy to mask 
the original exception or loose the traceback, and then you spend hours (if not days) trying to 
realize what had gone wrong. If you're not sure whether you should catch this or that exception,
don't. It's much easier to add exception handling later, where it's deemed necessary, than recover
from a lost traceback.

## Closing Words ##

I think the lesson to be learnt here is simple: **think before you act.** It's a very general
lesson, of course, but people tend to act dogmatically, without stopping for a moment to ponder
what they're doing and how (and if) it helps them.

Wrapping exceptions (when not adding information) hardly ever helps, and the same goes for 
overprotectivism. As the saying goes, *shit happens*; calling it in other names does not make
it smell better, so why bother? Files disappear, devices disconnect, sockets die, everybody lies.
That's life.

I started this post with some real-life examples I encountered, and in retrospective, it's easy
to see why they happen. Going back to ``get_device_info``, one of our modules *caught broadly* 
and *wrapped exceptions*; this combined with the overprotectionism of a second module, which masked
exceptions in favor of ``None`` (thinking it's better than propagating exceptions). At least three
different people were involved in this cross-module interaction, each handling exceptions 
recklessly (at different levels). In the end, we got a needlessly hard-to-debug situation; you see,
trying to make "robust code" usually means you're only hiding errors; good code crashes, allowing 
unittests to uncover more bugs, thus increasing robustness.

## On the Granularity of Exception Classes ##

Some people are rather laconic and use a single exception for everything. I've even people who were
so lazy that they used ``raise Exception("foo")`` directly, instead of deriving an exception class 
of their own... trying to handle such an exception calls for ``except Exception``, in which case
you'd break the first rule. People, it only takes one line to derive an exception class, there's 
no excuse for being **that lazy**! 

On the other hand, some people are way too verbose: they define specific exceptions for every 
minute detail, so they end up with dozens of exception classes, many of which are logically 
overlapping (I've seen this happen). This makes the implementation cumbersome (as you have to 
remember the dozens of exceptions you've defined), and, in fact, it might not be useful at all
for your users, and you might contaminate your "interface" with implementation details. 

The conclusion is that **the granularity at which exception classes are defined should match the 
granularity at which exception handling is done**: define separate exceptions (only) where it 
makes sense to handle one differently than the other.

For example, it makes sense to handle a ``ConnectionError`` differently from an 
``InvalidCredentials`` error, so the two are disparate: In the first case, you'd probably just
display an error message and quit. In the second case, you might prompt the user for his/her 
credentials once more.
 
On the other hand, if there's no reason to handle ``ConnectionFailedServerNotListeningOnPort`` 
differently from ``ConnectioFailedServerCrashedAcceptingSocket``, why make the distinction? 
A single ``ConnectionError`` is enough. 

**Note:** the error message may (and should) be different in each case -- **always include all the
available information** -- but keep in mind it's only meaningful for logging/diagnostic purposes, 
not for recovery.


