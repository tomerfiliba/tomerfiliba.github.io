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
of the subject, it's better to think of combinators as simple building-blocks that can be *combined*
in all sorts of ways to construct more complex entities. How complex? Well, consider these
building-blocks: identity (`Ix = x`), constant-lifting (`Kxy = x`), and substitution 
(`Sxyz = xz(yz)`) -- these three, known as the [SKI basis](http://en.wikipedia.org/wiki/Ski_combinators),
turn out to be equivalent in power to lambda calculus, which automatically makes them 
Turing-equivalent.

There's also the ever famous [Y combinator](http://en.wikipedia.org/wiki/Fixed-point_combinator),
(one of a family of *fixed-point combinators*), which, given a function `f` returns a function `p` 
such that `p = f(p)`. Fix-point combinators are interesting because they introduce the concept of 
*anonymous recursion*, i.e., recursion without the need for free variables. 

So we have yet another *model of computation* which is Turing-equivalent; this is interesting on 
its own, as it means three simple combinators (by the way, a single combinator is enough) are 
"powerful enough", but what's good does that serve? Well, so far, we've had Turing machines and 
λ-abstractions, both of which we treated as black-boxes; combinators, on the other hand, allow us 
to define weaker formalisms or domain-specific languages (DSLs) for different tasks. This enables 
us to reason more deeply about what we're doing.

### Baking Combinators ###

Suppose you want to bake a cake. Doing it manually, on your own?! Pfffft. One option is to take 
a general-purpose, Turing-complete robot, program-in the recipe and cross your fingers... but as 
we said earlier, there's not much you can do in advance if you had a bug and your robot starts 
cooking people instead. So yet another option would be to give the robot "just the right amount 
of power" (in this case, it's probably the same power as that of regular-languages) and the right 
"tools of the trade". This is similar to the principle of 
[least privilege](http://en.wikipedia.org/wiki/Principle_of_least_privilege) -- which people 
often use when it comes to resource management, but they seem to forget computation is a 
resource to be protected as well. To quote a [famous poet](http://www.youtube.com/watch?v=xC03hmS1Brk),
"guns don't kill people, cooking robots with guns kill people".

<a href="http://www.pamsclipart.com/clipart_images/bowl_of_cookie_dough_for_chocolate_chip_cookies_0515-0906-2514-3448.html">
<img src="http://www.pamsclipart.com/clipart_images/bowl_of_cookie_dough_for_chocolate_chip_cookies_0515-0906-2514-3448_SMU.jpg"
style="float: right; width: 250px;"/></a>

In this example, our ingredients are `FLOUR`, `WATER`, `EGG`, `MILK`, `BUTTER`, and `SUGAR`. 
Our "tools of the trade" are `PUT howmuch what`, which takes the specified amount of the specified
ingredient and puts it in the bowl; `STIR howmuch`, which stirs the ingredients in the bowl for 
the specified amount of time; and `BAKE temp time`, which sends the contents of the bowl to the 
oven for the specified amount of time at the given temperature. We'll also throw in some units
of measurements. Last, we'll need a `x THEN y` combinator that performs `x` and then `y`, 
also known as *sequencing*. 

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
*   It's much easier to write recipes this way! The expressive power of this DSL fits exactly what
    we need to do, without interferences like for-loops or if-branches. Keep it simple.

Also notice how this recipe is basically an expression. Think of `THEN` as a binary operator, 
such as `+`. You can now say `RockHardCake = PUT 5cups FLOUR + PUT 2 EGG + ...`, and you can
even go further to define new building blocks. Suppose mixing things with eggs and stirring
for 2 minutes is a common task. You could define 

    MIX-WITH-EGGS howmuch what = PUT howmuch what + PUT 2 EGG + STIR 2min

Such combinators could be expanded like macros at "compile time", given that we don't give our 
robot a runtime stack.

Now suppose that want to speed up the baking, so we got the robot a second bowl. This allows us 
to do things in parallel. For that we'll extend our vocabulary with `PAR x y`, which means `x` 
and `y` happen in parallel, each in a separate bowl; the semantics of `PAR` states that it 
continues execution only when both `x` and `y` have finished. Let's do things faster!

    PAR (PUT 5 EGG + PUT 1cup SUGAR + STIR 5min) 
        (PUT 2cup FLOUR + PUT 1cup WATER + STIR 2min) +
    MIX-BOWLS + 
    STIR 1min + 
    BAKE 200C 20min

Because this DSL is not Turing-complete, we can tell just by following a recipe that it will
finish in that-many minutes, and that it would never hang (simply because it can't). We can also
analyze all the possible failures the robot might have, like running out of sugar, in advance.
This way we can avoid baking at all if we conclude we'll run out of ingredients during the process.

So by **reducing the overall computational power** we've got, we can gain more **expressive power**
in our limited domain (baking), which allows us to **reason about recipes**. For instance, I can 
let you run recipes on my robot, because I know that no matter how bad the cake will come out -- 
it won't destroy humanity. It's a nice invariant of baking.

### Combinators Galore ###

Combinators are everywhere. You've surely seen and used them before, without realizing it:
shell pipes, cooking recipes, etc. Most of the time, though, combinators come equipped with 
too much power, which means there's little reasoning you can do about them. However, as we've
just seen, by limiting the power and choosing the right combinators carefully, there's much
we can achieve. Here are two real-life examples:

*   [Parsec](http://www.haskell.org/haskellwiki/Parsec), which builds parsers by combining very 
    simple building blocks. In theory, the framework could analyze your parser and optimize it,
    if it's simple enough (e.g., LL(k), LALR, ...)
*   [Drawing Combinators](http://hackage.haskell.org/packages/archive/graphics-drawingcombinators/latest/doc/html/Graphics-DrawingCombinators.html),
    library, which defines the building blocks of drawings. For instance, in order to draw a
    200x400 red rectangle at position (100,50), you'd start with a 1x1 square, scale it, color
    it red, and finally translate it to (100,50). This means you compose complex pictures out of 
    simpler and simpler pictures, in a pixel-perfect way. It turns the imperative drawing of 
    pictures into expressions; a "drawing calculus", if you wish.

For more info, have a look at the [Combinator Pattern](http://www.haskell.org/haskellwiki/Combinator_pattern).


