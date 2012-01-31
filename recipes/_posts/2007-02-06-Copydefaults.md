---
layout: recipe-page
title: Copy Function Defaults
---

Default arguments to functions are evaluated when the function is created, and are stored in the 
function object. This cause irritating problems when the default values are in fact mutable, 
as only single instance exists:

{% highlight pycon %}
>>> def f(x = []):
...     x.append(5)
...     print x
...
>>> f()
[5]
>>> f()
[5, 5]
>>> f()
[5, 5, 5]
{% endhighlight %}

Sometimes it's the desired behavior, but mostly it's a bug. To solve that bug, we use

{% highlight pycon %}
>>> def f(x = None):
...     if x is None:
...         x = []
...     x.append(5)
...     print x
...
>>> f()
[5]
>>> f()
[5]
>>> f()
[5]
{% endhighlight %}

But this idiom adds lots of boilerplate code into functions. The following little decorator solves that problem elegantly.

## Code ##
{% highlight python %}
from copy import deepcopy

def copydefaults(func):
    defaults = func.func_defaults
    def wrapper(*args, **kwargs):
        func.func_defaults = deepcopy(defaults)
        return func(*args, **kwargs)
    return wrapper
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> @copydefaults
... def f(x = []):
...     x.append(5)
...     print x
...
>>>
>>> f()
[5]
>>> f()
[5]
>>> f()
[5]
{% endhighlight %}


