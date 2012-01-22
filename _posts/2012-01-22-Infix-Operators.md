---
layout: post
title: Infix Operators in Python
---

As you may already know, there are 3 kinds of operators calling-notations: **prefix** (`+ 3 5`), 
**infix** (`3 + 5`), and **postfix** (`3 5 +`). Prefix (as well as postfix) operators are used 
in languages like LISP/Scheme, and have the nice property of not requiring parenthesis — 
there’s only one way to read an expression like `3 5 + 2 *`, unlike `3 + 5 * 2`. 
On the other hand, it reduces code readability and the locality of operators and their arguments.
This is why we all love infix operators.

Now imagine I have a function, `add(x,y)`, and I have an expression like `add(add(add(5,6),7),8)`...
wouldn’t it be cool if I could use infix notation here? Sadly though, Python won’t allow you to 
define new operators or change how functions take their arguments... but that doesn’t 
mean we have to give up!

Haskell, for instance, allows you to define custom operators and set their precedence, as well 
as invoking "normal" functions as infix operators. Suppose you have a function `f(x,y)` — you 
can invoke it like `f 5 6` or <code>5 `f` 6</code> (using backticks). This allows us to turn 
our previous expression, `add(add(add(5,6),7),8)`, into <code>5 `add` 6 `add` 7 `add` 8</code>, 
which is much more readable. But how can we do this in Python?

Well, there’s this [Cookbook recipe](http://code.activestate.com/recipes/384122-infix-operators/) 
that provides a very nice way to achieving the same functionality in Python (adapted a little by me):

{% highlight python %}
from functools import partial

class Infix(object):
    def __init__(self, func):
        self.func = func
    def __or__(self, other):
        return self.func(other)
    def __ror__(self, other):
        return Infix(partial(self.func, other))
    def __call__(self, v1, v2):
        return self.func(v1, v2)
{% endhighlight %}

Using instances of this peculiar class, we can now use a new "syntax" for calling functions as 
infix operators:

{% highlight pycon %}
>>> @Infix
... def add(x, y):
...     return x + y
...
>>> 5 |add| 6
11
{% endhighlight %}

Surrounding decorated functions with pipes (bitwise ORs) allows them to take their parameters 
infix-ly. Using this, we can do all sorts of cool things:

{% highlight pycon %}
>>> instanceof = Infix(isinstance)
>>>
>>> if 5 |instanceof| int:
...     print "yes"
...
yes
{% endhighlight %}

And even [curry](http://en.wikipedia.org/wiki/Currying) functions:

{% highlight pycon %}
>>> curry = Infix(partial)
>>>
>>> def f(x, y, z):
...     return x + y + z
...
>>> f |curry| 3
<functools.partial object at 0xb7733dec>
>>> g = f |curry| 3 |curry| 4 |curry| 5
>>> g()
12
{% endhighlight %}

Ain’t that cool?

