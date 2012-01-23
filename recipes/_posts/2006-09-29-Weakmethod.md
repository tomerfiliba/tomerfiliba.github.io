---
layout: recipe-page
title: Weak Methods
---

Many times you would pass bound methods to other functions, as callbacks (i.e., to simulate events,
etc.). However, bound methods (the `instancemethod` type) hold a strong reference to their owning 
instance (`im_self`), which means the existence of a bound method is enough to hold the instance 
"alive", even though your code has lost all references to it.

Sometimes it's the desired behavior -- but not always. This nifty decorator will solve the problem 
by returning a "weakly-bound" method, which means the method will not hold the instance alive. 
You'll get `ReferenceError` if you try to invoke the method, after the instance has died.

## Code ##

{% highlight pycon %}
from weakref import proxy
from types import MethodType

class weakmethod(object):
    __slots__ = ["func"]
    def __init__(self, func):
        self.func = func
    def __get__(self, obj, cls):
        if obj is not None:
            obj = proxy(obj)
        return MethodType(self.func, obj, cls)
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> class Foo(object):
...     @weakmethod
...     def bar(self, a, b):
...             print self, a, b
...
>>> f = Foo()
>>> b = f.bar
>>> b
<bound method Foo.bar of <weakproxy at 009FA1E0 to Foo at 009FC070>>
>>> b(1, 2)
<__main__.Foo object at 0x009FC070> 1 2
{% endhighlight %}

And when we delete the instance `f`:

{% highlight pycon %}
>>> del f
>>> b
<bound method Foo.bar of <weakproxy at 009FA1E0 to NoneType at 1E1D99B0>>
>>> b(1,2)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "<stdin>", line 4, in bar
ReferenceError: weakly-referenced object no longer exists
{% endhighlight %}



