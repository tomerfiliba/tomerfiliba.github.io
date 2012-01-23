---
layout: recipe-page
title: Hooking dir()
---

While working with proxy objects I found introspection quite hard, as the mechanism of `dir()` 
just looks at the object's `__dict__` (with some exceptions), and there's no way to customize 
this introspection. But do not fear, hacking skillz are near! After reading into the machinery 
of `dir()`, I found a nifty solution to this problem.

Note: since python 2.6, `__dir__` is a special method that's invoked by `dir()`, if it exists,
so there's no reason to use this code. Use only on earlier versions of python.

## Code ##

{% highlight python %}
__members__ = property(lambda self: self.__dir__())
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> class CustomDir(object):
...     __members__ = property(lambda self: self.__dir__())
...
...     def __dir__(self):
...         return "a list of fake attributes".split()
...
>>> c = CustomDir()
>>> dir(c)
['__class__', '__delattr__', '__dict__', '__dir__', '__doc__', '__getattribute__', 
'__hash__', '__init__', '__members__', '__module__', '__new__', '__reduce__', 
'__reduce_ex__', '__repr__', '__setattr__', '__str__', '__weakref__', 'a', 
'attributes', 'fake', 'list', 'of']
{% endhighlight %}

