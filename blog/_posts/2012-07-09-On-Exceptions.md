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
implementation** in some modules (and I think I've shown the correlation pretty well). 
I said that it's silly, because **Python is not subject to the same limitations** of Java, 
which dictate how the Java implementation works. I'm not going to open the discussion over 
whether OOP is good or bad, or mix-ins vs. interfaces, etc. -- I'm simply saying that "Java 
concepts" (which I called *Javaisms*) seem to enter Python **for no good reason**, meaning, in 
Python we have better (more Pythonic) ways to do it. I hope the scope of my discussion is clear now.

## When Life Throws Lemons At You ##

In this installment, I'm going to discuss how to **properly work with exceptions**, based on my 
experience with large-scale Python projects. In fact, this series was born after I got frustrated 
with the code quality of a certain library that my team develops. Instead of discussing code
snippets here, I'll share a some representative examples that I encountered:

* I used a function in the spirit of ``open_device(devfile)``, and passed a nonexistent device file 
  (for testing purposes or by mistake). Knowing how the library works, the underlying error was
  ``IOError(ENOENT)``, but what I got back was a silly ``DeviceDoesNotExistError``.

* I called ``get_device_info()`` and it simply returned ``None``. Further investigation showed that 
  my machine had a more recent version of a dependency installed on it, where some method's name 
  had changed. At some point (deep down the stack), the code used ``except Exception`` (catching 
  the unrelated ``AttributeError``) and translated it into a ``DeviceError``. Then, 
  ``get_device_info`` just swallowed all ``DeviceErrors`` and returned ``None``.

* I called a function such as ``enumerate_all_devices()`` and it returned an empty list.
  At first I was told "Of course, this library isn't supposed to work on Ubuntu, only on RHEL". 
  Further (and tedious) investigation showed it simply needs to run as ``root``; the code just
  assumed that any error during the execution an external tool meant it's not installed. 

This kind of stuff happens to me every time I get to an unexplored corner of the code, and I've 
already devised a method for debugging such cases: I comment-out all exception handling code along 
the way, until I find the actual error. In fact, this is essentially the treatment that I'm about 
to suggest here: 

<span style="display: block; width=100%; background: #FFA"> 
The first rule of exception handling is: **Don't handle exceptions**</span>

## Do Not Catch Broadly ##

<span style="background: #FFA">Always catch only the most-derived/most-specific exception.</span>
I believe this rule is very obvious
in theory, but harder to follow in practice: the number of exceptions might be large and their 
handling similar; you have to *import* specific exceptions from libraries, which tightly-couples
your code with implementation details; some libraries don't use a common exception base class for
all of their exceptions, which leads to many isolated ``except``-clauses.

All in all, you might have attenuating circumstances, but try to stick to this rule as much 
as possible. On the other hand, **never use a bare ``except:``**! Such an ``except``-clause will 
catch **all exceptions**, including ``SystemExit`` and ``KeyboardInterrupt``. So unless you plan 
to loose the ability to Ctrl-C a running program, or even prevent it from terminating gracefully, 
take the extra step and use ``except Exception``.

## Do Not Be Overprotective ##

A tendency I find in many programmers is being *overprotective towards their users*, to the point
where it seems like paternalism. It's as if they try to "hide away" all the complexities of life 
and present the user with an easy-to-swallow explanation. I should say that this phenomena 
virtually doesn't exist in **open-source** code, but in closed-source projects I find it all over 
the place. In fact, programmers have told me that's exactly what they're doing -- protecting their 
users. 

Well, as the saying goes, **we're all consenting adults here**. You should expect your users, as 
**programmers**, to have sufficient background; don't treat them like babies, and don't try to
"protect" them by throwing a "user-friendlier" ``FileNotFoundError`` instead of the "raw" 
``IOError``. Besides, keep in mind that the underlying exception usually holds all the needed
information in a very readable manner, e.g.,

    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    IOError: [Errno 2] No such file or directory: '/dev/nonexistent'

and anyone with some common sense would be able to cope with it. 
<span style="background: #FFA">Unless you can add meaningful information to the error, just let 
whatever came at you propagate up cleanly</span> -- we'll take it like men (or women!).

### A Note On Real Users ###

A question then arises: **what about non-programmer end-users?** What if my product's a GUI/CLI 
and a nasty stack trace suddenly shows up? 

Well, first of all, **this rule only deals with libraries** and other products whose end users are 
programmers. But on second thought, would it matter whether an ``IOError`` or a ``FileNotFoundError``
reaches the surface? The human user cares mostly for a descriptive and easy to understand **error
message**; the traceback or exception's type are mostly of interest to programmers.

But then again, when it comes to non-programmers, I don't want to get into generalizations. 
They might as well **not be** consenting adults... 

## Do Not Wrap Exceptions ##

Prior to Python 3, raising an exception during the handling of one, meant the original traceback
was lost. This has been finally solved, but Python 2.x still accounts for the majority of the 
code-base. Once you loose the traceback, debugging the problem is much harder as you can't use a 
debugger (``pdb``) or even tell *where* the exception came from... And when it happens off-site, 
on a customer's production server, you're screwed.

I believe *exception wrapping* in Python is an uncalled-for *Javaism*. It's a sort of a Java 
mind-set, where you'd like a library to be contractually obliged to throwing only a certain kind 
of exceptions. For instance, a queue library might raise exceptions such as ``QueueFull`` and 
``QueueEmpty``, both of which derive from ``QueueError``. Later, support is added for dumping a 
queue to a file, where an ``IOError`` might happen; because they're "obligated" to throwing only 
``QueueErrors``, they might wrap the underlying ``IOError`` by a ``QueueError``. **Don't do that**.

It is reasonable that ``FooLibrary`` would only throw exceptions that derive from ``FooError``, 
but only when these exceptions **originate** in ``FooLibrary``. An underlying ``IOError`` has 
nothing to do with your library, it could happen any time for various reasons! The same goes for 
an HTTP library that might get an ``ECONNRESET`` while talking over a socket -- the underlying 
``socket.error`` is not clearly not an ``HTTPError`` (or any of its descendants), and should not 
be wrapped by one. Besides, there are so many things that could go wrong, especially in a dynamic 
language like Python, that it makes no sense to wrap everything.

It only makes sense to wrap an underlying exception where you can provide additional information 
on it, or where you want to *change the semantics* of it. A classical such case is 
``connect-with-retries``, where you might want to allow several failures before giving up. Here,
you'd probably want to "accumulate" the intermediate exceptions and raise a 
``ConnectionError("%d connection attempts failed", accum_exceptions)``.

Bottom line: <span style="background: #FFA">wrap an exception only you **add information** about 
the root cause of the problem;</span> there has to be **good reason**
for wrapping it.

## Do not Handle Exceptions ###

Let me rephrase that: exceptions should be handled only

* where it's possible to **fix/recover** from the problem. For instance, if you get an ``EINTR``
  error when ``accept()``ing on a socket, it makes sense to swallow it and retry. Another use case
  is for fallbacks: first try to take the short way, and if it fails, take the long route.
  There are **many more** examples of handling an exception, of course, but you have to ask 
  yourself whether you're really fixing a problem or just masking it.

* where **cleanup/rollback** is necessary. It may be the case that you need to run rollback code
  only if an exception occurs (to release resources, etc.), so a ``finally``-clause or a *context
  manager* won't do. In this case you can ``except Exception``, do the rollback, and ``raise``
  (without passing any arguments to ``raise``).

* in the **main function**. Instead of letting the application crash with a traceback, you might 
  want to log the exception to a file, pop up a message box, ask the user what to do next, etc.

In other words: <span style="background: #FFA">handle exceptions only where you're actually 
**handling** them.</span>. It might seem obvious, but you'd be surprised how many times I find 
code that handles exceptions for no good reason. For example, people think that by swallowing
all sorts of exceptions and returning ``None``, they make their code "more robust"; that's lying
to yourself! You take a problem and make it worse, because it's very easy to mask the original
exception that way, and because you're hiding real problems. 

I've encountered countless times code that follows a pattern such as ``except Exception: 
log.error(...)``, which **hides bugs** like a misspelled variable. Logging is not handling the
exception. In the end, nobody ever reads the log, or even takes the time to properly configure it, 
so you ship a "very robust" product that has half the functionality you think it has.

## Closing Words ##

The lesson to be learnt here is: think before you act. Don't act dogmatically, don't follow Java 
paradigms for no reason, and try to keep your footprint as low as possible when it comes to 
error handling. As the saying goes, **shit happens**; calling it in other names (*exception 
wrapping*) does not make it smell better. Files disappear, file permissions get screwed, devices 
disconnect, sockets die, everybody lies. That's life.

Going back to the three bullets I opened this post with, you can see how by being overprotective
and by excessively wrapping exception, an ``AttributeError`` became a ``DeviceError``, which
then became ``None``. And you can see now why the first thing I do is remove all exception-
handling code along the way: most of the times it just masks the real error, making it harder to 
diagnose while adding little or no added value at all. You don't make your code more robust by 
sweeping problems under the carpet: good code crashes, allowing tests to uncover more bugs, 
increasing robustness.

## On the Granularity of Exception Classes ##

Some people are rather laconic and use a single exception for everything. I've even people who were
so lazy that they used ``raise Exception("foo")`` directly, instead of deriving an exception class 
of their own... People, it only takes one line to derive an exception class, there's no excuse for 
being **that lazy**! 

On the other hand, some people are way too verbose, defining specific exceptions for every minor 
detail. They end up with dozens of exception classes, many of which are logically overlapping.
This makes the implementation cumbersome, and, in fact, might not be useful at all for your users:
they usually won't care for such granularity, and you might contaminate your interface with
implementation details. 

The best practice here is: <span style="background: #FFA">the granularity at which exception 
are defined should match the granularity at which exception handling is done</span>; define 
separate exceptions (only) where it makes sense to handle one differently than the other.

For example, it makes sense to handle a ``ConnectionError`` differently from an 
``InvalidCredentials`` error, but there's usually little sense in making the distinction between
"connection failed because server is not listening" to "connection failed because server crashed 
after accepting us". Either way, **always include all the available information** in the error 
message -- but keep in mind it's only meaningful for logging/diagnostic purposes, not for in-code
exception handling.


