---
layout: blogpost
title: Regarding Infix Operators
description: Some more thoughts regarding the 'infix operators' post
tags: [python]
imageurl: http://tomerfiliba.com/static/res/2012-01-25-dog.jpg
---

I got some reactions to the [Infix Operators](http://tomerfiliba.com/blog/Infix-Operators) post, and wanted to point
out some things. First of all, I'm not the one who came up with it -- it's a recipe from the 
Python Cookbook that's been posted in 2005. I'm not taking credit for it or anything, I just
said I loved the idea and I adapted the code a little. 

Second, regarding coding style or the *pythonicity* of this scheme -- let's be clear, it's a hack.
In order for it to work, the two arguments must refuse to support `__or__` on `Infix` objects,
which means you can't compose them properly:

{% highlight pycon %}
>>> @Infix
... def dot(f, g):
...     return lambda *x: f(g(*x))
... 
>>> @Infix
... def mul(x, y):
...     return x * y
... 
>>> def double(x):
...     return x * 2
... 
>>> f = double |dot| mul   # this works ok
>>> 
>>> g = mul |dot| double   # but this won't
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "<stdin>", line 5, in __or__
TypeError: mul() takes exactly 2 arguments (1 given)
{% endhighlight %} 

It's also magical and unpythonic by nature. You can read in the cookbook comments about a
less-experienced programmer who complained he had to wrap his head around around this. I'd say this
feature is a kin to *metaclasses*: they are useful (at times), but there are better, more pythonic
ways to do the same without the magic.

So why is it useful? First of all, it's an interesting pattern, worth more knowing about
than actually using it. But on the more practical side, it could be very useful in 
domain-specific languages (DSL), where it could increase your expressiveness. Consider something
like [Construct](http://construct.wikispaces.com), where you define data structures declaratively:

{% highlight python %}
ipaddr = Struct("ipaddr",
    UInt8("a"),
    UInt8("b"),
    UInt8("c"),
    UInt8("d"),
)

lenval = Struct("lenval",
    UInt8("len"),
    Bytes("val", lambda ctx: ctx.len),   # interdependencies: "val" is `len` bytes long
)
{% endhighlight %}

We could replace all sorts of built-in constructs by such "operators", thus building "data 
expressions". So here's a very early sketch of what it could look it:

{% highlight python %}
ipaddr = UInt8 |seq| UInt8 |seq| UInt8 |seq| UInt8

# or maybe just
ipaddr = UInt8 |repeat| 4

# binding names into the context
lenval = UInt8 |bind_seq("len")| Bytes(getctx("len"))
{% endhighlight %}

Beware: I just made this up, there's no solid concept behind it. 


## See Also ##
If you liked the infix operators idea, have a look at <https://github.com/JulienPalard/Pipe>,
which allows for easy functional composition in python.

