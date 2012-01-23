---
layout: recipe-page
title: ExceptionContainer
---

An exception baseclass inspired by [Container](/recipes/Container), which takes keyword arguments
instead of positional ones, and provides pretty-printing in tracebacks.

## Code ##

{% highlight python %}
#
# module ExceptionContainer.py
# requires the Container module
#
from Container import Container


class ExceptionContainer(Exception):
    def __init__(self, message = "", **kw):
        self.__dict__["__info"] = Container(message = message, **kw)
    def __delattr__(self, name):
        delattr(self.__dict__["__info"], name)
    def __getattr__(self, name):
        return getattr(self.__dict__["__info"], name)
    def __setattr__(self, name, value):
        setattr(self.__dict__["__info"], name, value)
    def __repr__(self):
        return repr(self.__dict__["__info"])
    def __str__(self):
        return str(self.__dict__["__info"])
{% endhighlight %}

## Example ##

{% highlight pycon %}
>>> class FileNotFoundError(ExceptionContainer):
...     pass
...
>>> raise FileNotFoundError("failed to open the file!", filename = "/tmp/blah", errno = 17)
Traceback (most recent call last):
  File "<stdin>", line 1, in ?
__main__.FileNotFoundError: Container:
    errno = 17
    filename = '/tmp/blah'
    message = 'failed to open the file!'
>>>
>>> try:
...     raise FileNotFoundError("failed to open the file!", filename = "/tmp/blah", errno = 17)
... except FileNotFoundError, ex:
...     ex.errno = 18
...     raise
...
Traceback (most recent call last):
  File "<stdin>", line 2, in ?
__main__.FileNotFoundError: Container:
    errno = 18
    filename = '/tmp/blah'
    message = 'failed to open the file!'
>>>
{% endhighlight %}
