---
layout: recipe-page
title: Real Mixins
---

The normal python paradigm for implementing mixins is using multiple inheritance. Mixin classes 
take some measures of precaution as of their design (not to interfere with the *derivee*'s MRO as
much as possible), but they are essentially just regular classes, being derived from.

This code here creates **real** mixed-in classes: it actually merges one class into another 
(`CPython` specific), taking care of name-mangling, some complications with `__slots__`, and 
everything else. As a side-effect, you can also use it to mix **modules** into classes.

## Code ##

{% highlight python %}
import inspect

def mixin(cls):
    """
    mixes-in a class (or a module) into another class. must be called from within
    a class definition. `cls` is the class/module to mix-in
    """
    locals = inspect.stack()[1][0].f_locals
    if "__module__" not in locals:
        raise TypeError("mixin() must be called from within a class definition")
    
    # copy the class's dict aside and perform some tweaking
    dict = cls.__dict__.copy()
    dict.pop("__doc__", None)
    dict.pop("__module__", None)
    
    # __slots__ hell
    slots = dict.pop("__slots__", [])
    if slots and "__slots__" not in locals:
        locals["__slots__"] = ["__dict__"]
    for name in slots:
        if name.startswith("__") and not name.endswith("__"):
            name = "_%s%s" % (cls.__name__, name)
        dict.pop(name)
        locals["__slots__"].append(name)
    
    # mix the namesapces
    locals.update(dict)
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> class SomeMixin(object):
...     def f(self, x):
...         return self.y + x
...
>>> class AnotherMixin(object):
...     def g(self):
...         print "g"
...
>>>
>>> class Foo(object):
...     mixin(SomeMixin)
...     mixin(AnotherMixin)
...     
...     def h(self):
...         print "h"
...
>>> f = Foo()
>>> obj = Foo()
>>> obj.y = 18
>>> dir(obj)
['__class__', '__delattr__', '__dict__', '__doc__', '__getattribute__', 
'__hash__', '__init__', '__module__', '__new__', '__reduce__', 
'__reduce_ex__', '__repr__', '__setattr__', '__str__', '__weakref__', 
'f', 'g', 'h']
>>> obj.f
<bound method Foo.f of <__main__.Foo object at 0x00A96710>>
>>> obj.g
<bound method Foo.g of <__main__.Foo object at 0x00A96710>>
>>> obj.h
<bound method Foo.h of <__main__.Foo object at 0x00A96710>>
>>> obj.h()
h
>>> obj.g()
g
>>> obj.f(4)
22
>>>
{% endhighlight %}

