---
layout: post
title: Property Classes
section: recipes
---

Tired of creating properties the old way? Python 3 brings an improvement in the form of 
multi-stage properties, i.e.,

{% highlight python %}
@property
def foo(self):
    ... # getter

@foo.setter
def foo(self, value):
    ... # setter
{% endhighlight %}

It still feels very awkward. I can't say my solution is pure elegance, but I find it cleaner.

## Code ##

{% highlight pycon %}
import types

def property_class(cls):
    getter = getattr(cls, "get", None)
    if isinstance(getter, types.UnboundMethodType):
        getter = getter.im_func
    setter = getattr(cls, "set", None)
    if isinstance(setter, types.UnboundMethodType):
        setter = setter.im_func
    return property(getter, setter)
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> class Person(object):
...     def __init__(self):
...         self._age = 17
...     @property_class
...     class age:
...         def get(self):
...             return self._age
...         def set(self, value):
...             self._age = value
...
>>> p = Person()
>>> p.age
17
>>> p.age=19
>>> p.age
19
{% endhighlight %}
