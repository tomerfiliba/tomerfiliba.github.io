---
layout: blogpost
title: All About Combinators
---

### With Great Power Comes Great Complexity ### 

First of all, allow me to clarify that I'm no mathematician, let alone a logician. I'm merely
interested in the [expressive power](http://en.wikipedia.org/wiki/Expressive_power) of various
formalisms: what ideas can we express, and how much reasoning can we do. This, of course, goes
hand-in-hand with formal language theory, as expressions are formalized in a *language*, and 
this, in turn, brings us to the domain of complexity theory.

For instance, think of good-old *regular expressions*. You can use them to define "patterns" and
match them on strings, but what kinds of patterns can you define with them? How far-reaching
is your expressive power? In this case, it's easy: regular expressions define the class of *regular
languages*, which have well-studied mathematical properties; for once, you cannot define a regular 
expression that will match parenthesis. On the other hand, it's easy to match them: regular 
languages are *decidable* by a *Finite State Automaton*, which means they can be matched in O(n)
time, where 'n' is the size of the input. If we try to increase our expressive power, by going up
to *context-free* languages, using formalisms such as [BNF](http://en.wikipedia.org/wiki/Backus_normal_form),
we need O(n^3) time to parse. Climbing higher in the [Chomsky Hierarchy](http://en.wikipedia.org/wiki/Chomsky_hierarchy)
will buy us more power, but increase the complexity even further... up until the parsing 
itself becomes undecidable.

So we begin to see a tradeoff between the expressive power of formalisms and their "reasoning":
the more you can say, the harder it is to "prove" or "reason about" it. 

### Great Power ###






