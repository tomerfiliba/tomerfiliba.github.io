---
layout: blogpost
title: Easy Syntax for Representing Trees
tags: [python]
description: Demonstrates a quick and readable way to represents trees in python code
---

I'm working on a parser for [Tree Adjoining Grammar (TAG)](http://en.wikipedia.org/wiki/Tree-adjoining_grammar) 
for this seminar I'm taking. TAG is an extension of context-free grammar (CFG) that's more powerful
while still being polynomially-parsable. Anyhow, TAG makes use of "tree production rules" instead of 
the "linear" production rules of CFG: instead of `S -> NP VP`, you'd have a small tree, the root of
which being `S`, having `NP` and `VP` as its children. Of course these trees can be more than 
two-level deep, and they go all sorts of operations such as substitution and adjunction, but that's
for the parser.

So I needed a compact and (hopefully) readable way to express such trees in my code. At first I 
used lots of parenthesis, which was ugly and cumbersome, but then I devised this:

{% highlight python %}
class NonTerminal(object):
    def __init__(self, name):
        self.name = name
    def __sub__(self, children):
        return Tree(self, children)
    def __pos__(self):
        return Foot(self)

class Foot(object):
    def __init__(self, nonterm):
        self.nonterm = nonterm

class Tree(object):
    def __init__(self, root, children):
        self.root = root
        self.children = children
{% endhighlight %}

And here's how you use it:

{% highlight python %}
S = NonTerminal("S")

t1 = S-["e"]
t2 = S-["a", S-["c", +S, "d"], "b"]

# Which represents the following two trees:
#
# t1:                t2:
#      S                  S 
#      |                / | \
#      |               /  |  \
#      e              a   S   b
#                       / | \
#                      /  |  \
#                     c   S*  d
#
{% endhighlight %}

The peculiar `+S` is a way to mark that a leaf node is a *foot*, which is part of the semantics TAG
(that's where adjunction takes place). It's represented in the diagram by the more conventional `S*`, 
but I had to resort to a unary operator in the code. Anyway, I'm not sure if it's a recipe or just
a nice trick, but I thought I'd share this.

By the way, you can use both `__sub__` and `__neg__` to achieve things like `S-----X` (i.e.,
more than a single `-` sign, to allow for better padding), but I tried to avoid too much ASCII art.
I'd love to hear about other such ideas!



