---
layout: blogpost
title: Introduction to Combinators, Part 1
---

### With Great Power Comes Great Complexity ### 

First of all, allow me to clarify that I'm no mathematician, let alone a logician. I'm merely
interested in the [expressive power](http://en.wikipedia.org/wiki/Expressive_power) of various
formalisms: what ideas can we express in them, and how much reasoning can we do about them. 
This, of course, goes hand-in-hand with formal language theory, as expressions are formalized in 
some *language*, and this, in turn, brings us to the domain of complexity and computability theory.

<a href="http://cartoon-for-all.blogspot.com/2010/08/spiderman.html">
<img src="http://2.bp.blogspot.com/_9UxHwUfG2qQ/THakYJh98aI/AAAAAAAACqE/ntDoCfzhk7s/s1600/spiderman1.jpg"
style="float: right; width: 250px;"></a>

Starting at the bottom, think of good-old *regular expressions*. You can use them to define "patterns" 
and match them on strings, but what kinds of patterns can you define? How far-reaching is your 
expressive power? In this case, it's easy: regular expressions define the class of *regular
languages*, which have well-studied mathematical properties; for once, you cannot define a regular 
expression that will match parenthesis. On the other hand, it's easy to match them: regular 
languages are *decidable* by a *Finite State Automaton*, which means they can be matched in O(n)
time, where 'n' is the length of the input. If we try to increase our expressive power, by going up
to *context-free* languages, using formalisms such as [BNF](http://en.wikipedia.org/wiki/Backus_normal_form),
we require O(n^3) time to parse. Climbing higher still in the [Chomsky Hierarchy](http://en.wikipedia.org/wiki/Chomsky_hierarchy)
will buy us more power, but will increase the complexity even further... up until the parsing itself 
becomes *undecidable*.

There's a tradeoff between how strong a formalism is and how much reasoning you can do about it.
For example, given a regular expression, and you could describe what it does or write the equivalent
C code; given a boolean expression such as `x AND (NOT x)`, you could say it always evaluates to 
`FALSE`. However, if I gave you a magical machine and told you it makes pizza, there's no way for
you to know (read: prove) that it actually does. It could one day make fudge brownies, or even 
enrich uranium, if it felt like it. 

### Great Power ###

The discussion of the pizza-making machine leads us directly to the 
[Halting Problem](http://en.wikipedia.org/wiki/Halting_problem):

> Given a description of a computer program, decide whether the program halts (finishes running) 
> or continues to run forever

The problem itself is quite meaningless, especially since Turing had proved (1936) it's impossible, 
but the idea behind it is important: it's a proof that *more power = less reasoning*. Many problems
are [reducible](http://en.wikipedia.org/wiki/Reduction_(complexity%29) to the halting problem; for 
instance, there could never be a program that validates the correctness of that another program,
meaning, you cannot (mechanically) prove that a piece of code is free of bugs (in the general case, 
of course). 

And now we get to a very interesting question: what is a "computer program", from a well-defined,
mathematical point-of-view? What is a *computation*? Are there things we simply 
[cannot compute](http://en.wikipedia.org/wiki/Chaitin%27s_constant)? 
The [Church-Turing thesis](http://en.wikipedia.org/wiki/Church%E2%80%93Turing_thesis) states that 
anything that can be "effectively computed" by an algorithm, is computable by a Turing machine.
This "thesis" is vague by nature, as it tries to capture the vague notion of what a computation is,
but it finally gives us a mathematical model to work with.

A Turing machine comprises of a "movable head" that slides on an endless tape, made of cells. Each
such cell contain an alphabet symbols (say, `0` or `1`), and the head can move left or right, 
read the symbol it currently stands on, or rewrite it. It's a surprisingly simple and *mechanical* 
description -- but it's stronger than any (finite) computer we'll ever have. You may already notice
the resemblance between Turing machines and the way von-Neumann computers work, but this 
formalism seems too "technical" or "low level"... is there another formalism we can use, of a 
more mathematical nature? Are there other *models of computation* that are equivalent in power?

The answer came at about the same time as the invention of the Turing machine: *Lambda (λ) calculus*, 
which looks at computability from a different angle: mathematical functions. Λ-calculus is 
concerned with λ-abstractions, which provide easy syntax and semantics for the definition of 
functions, such as `λx. x + 2` (a function that adds 2 to `x`). Since, these functions may be 
recursive, their power is equivalent to Turing machines, so that any program that can be expressed
in one formalism can be converted to the other (and in fact, this exact conversion is performed by 
compilers and interpreters of *functional languages*). 

The term "λ abstraction" is also very accurate, as it implies the notion of the black-box we 
discussed earlier: the only thing you can do with a λ function is apply it to arguments. 
So you may add a type system, to add some sanity, but a function is ultimately a black-box...

