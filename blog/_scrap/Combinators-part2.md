---
layout: blogpost
title: Introduction to Combinators, Part 2
---

### Combinators ###

Combinatory logic was introduced in the 1920's by Moses Schönfinkel, a Russian mathematician, 
as a way to eliminate bound/quantified variables from mathematical logic, in a pursuit of a 
more succinct form of logic; the concept was later successfully employed and extended by Haskell 
Curry. A combinator is basically a higher-order function (function that operates on functions) that
does not use free variables; again, the idea is to [eliminate variables](http://en.wikipedia.org/wiki/Tacit_programming).

<a href="http://www.cksinfo.com/sports/skiing/index.html"><img src="/static/res/ski.png"
style="float:right; width:250px;"></a>

Instead of going [deeper into the mathematics](http://en.wikipedia.org/wiki/Combinatory_logic#Combinatory_calculi)
of the subject, it's better to think of combinators as simple build-blocks that can be *combined*
in all sorts of ways to construct more complex ones. How complex? Well, the [SKI basis](http://en.wikipedia.org/wiki/Ski_combinators)
is equivalent to lambda calculus, which automatically makes it equivalent to Turing machines.
How do these combinators look? Really simple: you have identity (`Ix = x`), constant-    
(`Kxy = x`), and substitution (`Sxyz = xz(yz)`)... with these you can build back lambda 
abstractions and everything else. There's also the ever famous [Y combinator](http://en.wikipedia.org/wiki/Fixed-point_combinator),
or *fixed-point combinator*, which, given a function `f` returns a function `p` such that 
`p = f(p)`. Fix-point combinators are interesting because they introduce the concept of *anonymous 
recursion*, i.e., recursion without the need of free variables. 

So we have yet another *model of computation* which is Turing-equivalent; this is interesting on 
its own, as it means combinators are "powerful enough", but what's the point of that? Well,
so far, we've had Turing machines and λ abstractions, both of which were black-boxes to us;
combinators, on the other hand, let us define weaker formalisms or domain-specific languages (DSLs)
for different tasks. This enables us to reason about what we're doing.

### Baking Combinators ###

Suppose you want to bake a cake. One option is to take a Turing-complete robot, program-in the 
recipe and cross your fingers... but as we said earlier, there's not much you can do in advance
if the robot starts cooking people, if you had a bug. Another option is to give the robot 
"just the right amount of power" (in this case, it's probably the same power as that of 
regular-languages) and the right "tools of the trade".

<a href="http://www.pamsclipart.com/clipart_images/bowl_of_cookie_dough_for_chocolate_chip_cookies_0515-0906-2514-3448.html">
<img src="http://www.pamsclipart.com/clipart_images/bowl_of_cookie_dough_for_chocolate_chip_cookies_0515-0906-2514-3448_SMU.jpg"
style="float: right; width: 250px;"/></a>

In this example, our ingredients are `FLOUR`, `WATER`, `EGG`, `MILK`, `BUTTER`, and `SUGAR`. 
Our "tools of the trade" are `PUT howmuch what`, which takes the specified amount of the specified
ingredient and puts it in the bowl; `STIR howmuch`, which stirs the ingredients in the bowl for 
the specified amount of time; and `BAKE temp time`, which sends the contents of the bowl to the 
oven for the specified amount of time at the given temperature. We'll also throw in some units
of measurements. Last, we'll need a `x THEN y` combinator that performs `x` and then `y`, 
AKA *sequencing*. 

Using these building blocks, we can build recipes like so:

    PUT 5cups FLOUR
    THEN
    PUT 2 EGG
    THEN
    PUT 3cups SUGAR
    THEN
    PUT 2cups WATER
    THEN
    STIR 2min
    THEN
    BAKE 200C 30min

And we'll get a rock-hard cake. However, doing so, we've also gained two extra properties:

*   Our robot cannot become Skynet, simply because it's vocabulary cannot express ideas like 
    killing people or shooting guns.
*   It's much easier to write recipes... the expressive power of this DSL fits exactly what
    we need to do. We do not have for-loops or branches, and what we do need is easy.

Also notice how this recipe is basically an expression. Think of `THEN` as a binary operator, 
such as `+`. You can now say `RockHardCake = PUT 5cups FLOUR + PUT 2 EGG + ...`, and you can
even go further to define new building blocks. Suppose mixing things with eggs and stirring
for 2 minutes is a common task. You could define 

    MIX-WITH-EGGS howmuch what = PUT howmuch what + PUT 2 EGG + STIR 2min

If we wanted to speed up the process, we could buy the robot a second bowl, which allows us to do
things in parallel. For that we'll extend our vocabulary with `x PAR y`, which means `x` 
and `y` happen in parallel, each in a separate bowl; the semantics of `PAR` states that it 
continues execution only when both `x` and `y` have finished. Let's do things faster!

    (PUT 5 EGG + PUT 1cup SUGAR + STIR 5min) PAR (PUT 2cup FLOUR + PUT 1cup WATER + STIR 2min) +
    MIX-BOWLS +
    STIR 1min +
    BAKE 200C 20min

Because this DSL is not Turing-complete, we can tell just by following a recipe that it will
finish in that-many minutes, and that it would never hang (simply because it can't). So by reducing 
the overall computational power we've got, we can gain more expressive power in our limited domain
(baking), and be able to reason about recipes. For instance, I can let you run recipes on my robot,
because I know that no matter how bad the cake will come out -- it won't destroy humanity. 

### Closing Thoughts ###

Combinators are everywhere. You've surely seen and used them before, without realizing it:
shell pipes, cooking recipes, etc. Most of the time, though, combinators come equipped with 
too much power, which allows you for little reasoning about them. 

Two examples I'd like to share are:
*   [Parsec](http://www.haskell.org/haskellwiki/Parsec), which builds parsers by combining very 
    simple building blocks. In theory, the framework could analyze your parser and optimize it,
    if it meets certain conditions (e.g., LALR)
*   [Drawing Combinators](http://hackage.haskell.org/packages/archive/graphics-drawingcombinators/latest/doc/html/Graphics-DrawingCombinators.html),
    which defines the building blocks for creating drawings. For instance, in order to draw a
    200x400 red rectangle at position (100,50), you start with a 1x1 square, scale it, color
    it red, and translate it to (100,50).

For more info, have a look at [Combinator Pattern](http://www.haskell.org/haskellwiki/Combinator_pattern).


