---
layout: blogpost
title: Some Useful Design Patterns
published: false
description: 
tags: [python]
---

I wanted to diverge a little from the topics I've been covering recently (DSLs, GUIs, etc) into 
the more theoretical-but-practical grounds of design patterns. I'm sure you've heard about them
before, but I'd like to offer my view on the subject and highlight some of the design patterns
that I find the most useful. Although design patterns go hand-in-hand with the object-oriented
methodology, which I think less of, they are useful on their own as they tend to capture 
generalizations.

<a href="http://dryicons.com/free-graphics/preview/flower-pattern/">
<img src="http://tomerfiliba.com/static/res/2012-02-14-flower_pattern.jpg"
style="float: right; width: 250px;" title="Flower pattern" /></a>

## Null, State, Strategy and RAII ##

I'll begin with a bold claim: I don't distinguish between the [Null](http://en.wikipedia.org/wiki/Null_Object_pattern),
[State](http://en.wikipedia.org/wiki/State_pattern) and [Strategy](http://en.wikipedia.org/wiki/Strategy_pattern)
patterns. I see them as different projections of the same basic idea: don't rely on hard-coded 
`if`/`switch` statements to determine your flow; instead, move the runtime behavior to an external 
object. This makes your code more modular (easier to extend) and concise (shorter), at virtually
zero-cost.

*State* and *Strategy* are the "big gun" brothers of *Null*, but the idea, as I said, is the same.
Before going into an example, allow me to call yet another pattern into the arena: 
[RAII](http://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization), or *Resource Acquisition
is Initialization*. This pattern is well known and widely used in the C++ world, but it's has less
PR outside of it, mostly because C++ lacks a `try`-`finally` clause while other languages have it.
In short, RAII says you should "fully-initialize" the object at construction time, and put any
cleanup (`finally`) code in the destructor, because that's the only way to guarantee it will take
place in case of an exception. For instance, instead of first initializing an unopened `File` object
and then calling open() on it, have the constructor open the file at initialization. This way,
the lifespan of the object and the resource it represents are one.

Okay, why would be want to use RAII in a language like Python or Java? You wouldn't, but you would
like to borrow an idea from it: allocate resources at construction time. Linking the lifespan of 
the object and the resource it holds is a good practice. Since we're using a garbage-collected
language with support for `finally` clauses, we needn't bother ourselves with deallocation too much,
and besides, that's what [context managers](http://www.python.org/dev/peps/pep-0343/) are for.




Suppose you have a resource, e.g., a file or network stream. 

Python's `file` type is an excellent example of this: you cannot just create an unopened file,




* Null, State, Strategy, RAII 
* Reactor
* Observer
* Visitor
* Generic functions and [Parameteric Polymorphism](http://en.wikipedia.org/wiki/Parametric_polymorphism)

