---
layout: recipe-page
title: Module Mixins a la Ruby
---

Multiple inheritance is usually considered bad, and many ways to avoid it have been developed. 
The first and most notable is *interfaces*, which are basically abstract classes (only declaration,
no implementation). Another solution is mix-in classes, which add functionality ("implementation") 
to the class, but do not affect the inheritance tree.

Mixins differ from regular classes mostly by their semantics (after all, they are just classes):

* They would never derive from any class in the inheritance tree of the defined class
* They would never define an `__init__` method

Also, if class Dog is a subclass of class Animal, then an instance of Dog is an instance of Animal 
as well (up-cast). On the other hand, a class that derives from a mixin class isn't considered a 
subclass of that mixin class. For more info, see `DictMixin` in `UserDict.py`, or 
this [ruby tutorial](http://www.rubycentral.com/book/tut_modules.html#S2).

Ruby came with a strange idea -- **mixin modules**. I don't find this whole thing quite useful, 
as python (unlike ruby) supports multiple inheritance, but I wanted to show it's possible in 
python as well. So here's a two-liner metaclass decorator that does the trick.

Note: in ruby, adding a function to the module would also add it as a method of the class, but 
this is not the case here, as python imposes certain (arbitrary) limitations on that. Never mind.

## Code ##
{% highlight python %}
def mixin(mod):
    return type("mixin(%s)" % (mod.__name__,), (object,), mod.__dict__)
{% endhighlight %}

==Example==
This is the code of `testmixin.py`

{% highlight python %}
def foo(self, y):
    return self.x + y

@staticmethod
def boo(y):
    return 2 + y
{% endhighlight %}

And here's a snapshot demo:

{% highlight pycon %}
>>> import testmixin
>>>
>>> class Bar(mixin(testmixin)):
...     def __init__(self):
...         self.x = 8
...     def zoo(self):
...         return "zoo"
...
>>> b = Bar()
>>> b.zoo()
'zoo'
>>> b.foo(9) # foo is a method from testmixin
17
>>> b.boo(2) # foo is a staticmethod from testmixin
4
>>>
{% endhighlight %}
