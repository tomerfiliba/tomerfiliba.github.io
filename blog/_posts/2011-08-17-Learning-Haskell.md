---
layout: blogpost
title: Learning Me a Haskell
---

*Phew!* Finally the semester's over (just submitted my last project), and it's time to clean 
up my ever-so-long backlog. Here goes nothing: I'll start by posting something here, 
after this long while of neglect. 

As I'm sure you already know, I'm a long-time Pythonista, and I'm confident enough in calling 
myself a "native speaker" of that language. Although python is my expertise, I'd say I'm 
fluent in most other prominent programming languages (say, C, C++, Java, C#, VB), and with 
adequate knowledge of many more. It may seem like a good set of skills, but I have to admit 
this brings one to a point of stagnation. There comes a time where everything just looks the same: 
you take a glimpse at a new language/platform/other technology and sigh, "oh well, 
on the surface it's different, but underneath it's all the same sh*t". You come to the 
conclusion that people mostly change the looks-and-feel, but nothing radical could never happen. 
And then you skip to the next article.

Then came [Haskell](http://www.haskell.org/haskellwiki/Haskell): a statically-typed, type-inferred, 
highly-expressive functional language. I'm not new to functional programming -- I've programmed 
in Scheme, and I even wrote an interpreter for a toy functional-language that I made up in order 
to investigate nested-scopes and evaluation models -- but heck, **this one's different**. 
A friend of mine nagged me to learn Haskell for quite a time already, but I was deterred by 
Haskell's ugly syntax (it's not Python a'right) and I kept pushing it for "when I have time". 
It always seemed too academic to me, too impractical. 

I think what provoked me into seriously learning Haskell is a pattern called 
[continuation passing style](http://en.wikipedia.org/wiki/Continuation-passing_style) -- I was 
just amazed by the extra power, design simplicity, and greater expressiveness that you get with it.
Of course you can implement it in almost any other language, and in fact it was invented in 
Scheme (`call/cc`), but Haskell, with its purely-mathematical state of mind, just brings 
the best out of things. Haskell has also taught me that expressiveness and conciseness are 
not virtues to be underestimated: if you can do something in one line instead of four, 
you must be generalizing on some deeper concept that you've previously missed. 
It's not just looks-and-feel, this time.

But let's not go astray. I think the most prominent and well-known feature of Haskell is its 
excellent type system. I'm sure you've heard of *static languages*, like java or C++, 
where every expression has a compile-time type; and I'm sure you've heard of 
*dynamic (duck-typed) languages*, where there are only run-time types and no checks are (or can be)
performed prior to running the code. In the first case, you curse the compiler for limiting what
you can do (even when it makes perfect sense) and for being bluntly stupid, requiring you to repeat
yourself over and over (`FooBar x = new FooBar()`). And because most type systems are so weak, 
you find yourself escaping to "duck-typing" techniques like `void *` or `Object`, and relying on 
run-time casts. In the latter case, you find yourself trying to cover the infinite space of 
type permutations that your functions have to handle, and soon you pray for *some* sort of 
validation or restrictiveness.

When you start learning Haskell, you suddenly realize how weak most type systems are, and that 
there are (much) better alternatives. It's like you've been suffering from a blurry vision your 
whole life, and suddenly you realize you can wear glasses. Has it ever occurred to you that 
type systems are equivalent to proof systems 
(the [Curry-Howard isomorphism](http://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence))? 
And that a compiler basically tries to prove your code? You can think of compilation errors as 
finding a counter-example to your claim! "You said F takes an integer, but I see you try to call 
it with a String"... so of course this is a trivial example, one that even a C compiler catches, 
but you can make more complicated claims. And then you realize that type systems and compilers
("provers") do matter -- a smarter compiler that employs a more powerful type system can prove 
or disprove more complicated claims! That's a non-trivial conclusion that most programmers missed... 
type systems don't have to suck, and they can actually **work for you**, unlike Java.

But what do I know, I'm just learning Haskell now, and besides -- this post is but a teaser. 
So do yourself a favor and [Learn You a Haskell](http://learnyouahaskell.com/chapters)!



