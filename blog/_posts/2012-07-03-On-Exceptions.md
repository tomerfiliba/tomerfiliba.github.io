---
layout: blogpost
title: On Exceptions
draft: true
description: "Exceptions, logging and large-scale projects: how to do it right (part 1 of 2)"
---

<img src="http://tomerfiliba.com/static/res/2012-07-05-no-java.png" class="blog_post_image" />

## Javaism ##

I'm working nowadays on refactoring a large Python codebase at my workplace, and I wanted to share 
some of my insights over two crucial aspects of large-scale projects: *exceptions and logging* (and 
a bit on coding style, of course). Due to it's length, the first part covers exceptions, and a 
second installment will cover logging and code style.

From my long experience in the programming world, I get the feeling that many programmers
(even those fluent in Pythonspeak) come from a rich Java/.NET background, where they've learned 
their programming skills and mind-set. And just like speaking a second language, you can't deny 
your mother tongue: it will keep popping up here and there, subconsciously. In the context of 
this post, I'll refer to this as *Javaism*, or *thinking Java in Python*.

You don't have to go far to see examples of it, for Javaism didn't skip Python's standard library: 
modules/packages such as ``logging``, ``unittest`` and ``threading`` where ported almost 
isomorphically from Java. On the surface, you might encounter camelCase names (``getLogger``), 
but the verbosity and over-complicated nature of Java and its inheritance methodology can be seen 
anywhere. For instance, recall the complexity of setting up a logger (I have to look it up every 
time), or the ``threading.Thread`` class... I really don't wish to digress here, I feel that a 
concrete example would help me make my point:

* The canonical way to write thread functions is by subclassing ``Thread`` and implementing 
``run()``; you can pass a callback (called [target](http://docs.oracle.com/javase/6/docs/api/java/lang/Thread.html)),
  but it seems like an afterthrought. For once, it's not the first argument of the constructor.
* Speaking of the Thread constructor, it takes so many optional arguments (``group``?!), but you 
  have to imperatively call ``setDaemon()`` afterwards (instead of passing ``daemon = True`` to 
  the constructor). Why? Because that's the way Java did it.
* Also, you first *instantiate* the thread, then ``start()`` it... where's the sense in that?
  What can you *do* with an *unstarted* thread object (other than calling ``setDaemon``)? 
  Consider ``Popen`` or ``file()`` -- the *obvious way* in python is to follow
  [resource instantiation is acquisition](http://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization).
  Why introduce such transient, useless states in the lifetime of the object? The answer is that 
  in Java, there's no way to create "deferred" objects (lambda functions or 
  [partials](http://docs.python.org/library/functools.html#functools.partial)),
  so in order to reduce boilerplate, Java adds transient states everywhere. It's a common practice. 

Luckily, it seems to be a thing of the past, as if it only entered stdlib in the old days, before 
the community had a clear notion of what *being pythonic* meant. But still, Javaism of all degrees 
is widespread, especially in corporate-developed large-scale projects (Zope and twisted, to name 
a few).

## Exceptions ##

Java had a good insight (that they probably stole from some other language) in that exceptions are 
part of a function's signature. Just like a function takes an argument of type T1 and returns a 
result of type T2, it also has "side channels" through which it can produce results -- exceptions. 
But trying to foresee everything that might ever go wrong is a futile attempt, and even Java itself 
makes two exceptions (no pun intended): ``Error``, for unrecoverable exceptions (such as 
``VirtualMachineError``), and ``RuntimeException``, for exceptions that may always occur 
(such as ``NullPointerException``). 

The fundamental idea is good, but it was bound to fail: first, because people are lazy,
but most importantly, because trying to predict all unexpected, future edge cases is absurd. 
For instance, suppose you're implementing an interface that stores data (say, in files), so you 
might find yourself implementing a signature such as ``void write(byte[] data) throws IOException``.
Now suppose your implementation uses a third-party database engine, that throws ``MySQLException``.
For obvious reasons, ``MySQLException`` does not derive from ``IOException``, and there's nothing
you can do about it, as both the interface and the engine are given to you. You're now faced with
three options:

* Translate ``MySQLExceptions`` into ``IOExceptions``
* When designing interfaces, always declare the most general exception in ``throws`` clauses
* When implementing libraries, always derive your exceptions from an unchecked exception 
  (``RuntimeException``)

In short -- you need to **find a workaround to by-pass the compiler**. This essentially means that
the ``throws`` clause should have served for documentation-only purposes, where the compiler may 
produce (suppressible) *warnings* when you don't follow conventions. It's more of a semantic 
property, like idempotence or thread-safety... you wouldn't expect the compiler to *enforce* that.

I'd guess most people agree that the second and third options are "inherently bad", but opinions
diverge on the first. I will try to show that *exception-wrapping* (translating exceptions) 
is just as bad -- at least when it comes to Python. 

<div class="section" id="do-not-wrap" />

## Do Not Wrap Exceptions ##

Up until Python 3, raising an exception during the handling of a previous one, meant the traceback
was lost. This has been finally solved, but Python 2 still accounts for the majority of the code 
base. 

### Don't Handle Exceptions ###
Every time you use ``except``, pause for a while and think what are you really doing. Are you
*handling* the exception? Handling means you **fixed** the problem, and execution can continue
normally. 

<a href="http://www.apartmenttherapy.com/there-i-fixed-it-89037">
<img src="http://tomerfiliba.com/static/res/2012-07-05-i-fixed.png" class="blog_post_image" /></a>

And even if the traceback is preserved, you have to ask yourself **why** would your wrap
one exception by another? What good does it serve? And more generally, **why** do you even handle

* What are exceptions
* What to 'except'
* Don't handle unless you handle
* Don't protect the user
* Granularity of exception classes











