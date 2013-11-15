---
layout: etc-page
title: A Python Crash Course for the Statically Typed Programmer
draft: true
description: Python crash-course
imagelink: http://en.wikipedia.org/wiki/Ouroboros
imageurl: http://tomerfiliba.com/static/res/2013-11-15-ouroboros.png
imagetitle: Ouroboros
---

Python is a multi-paradigm (hybrid) language. It's fully object-oriented, but has strong functional roots.

If you had taken any academic course that involves programming, Python will most likely resemble pseudo code to you

{% highlight python %}
def factorial(n):
    if n <= 1:
        return 1
    else:
        return n * factorial(n - 1)

# or

def factorial(n):
    res = 1
    while n:
        res *= n
        n -= 1
    return res

{% endhighlight %}

You'll see inheritance and class diagrams along side with constructs imported from Haskell and LISP.

Python is dynamically-typed (as opposed to statically-typed) but has strong-typing 
(as opposed to -WTF- Perl or Javascript) 

<img src="http://tomerfiliba.com/static/res/2013-11-15-perl.png">

## Hello Snake ##

* The interactive interpreter is your friend

```
$ python
Python 2.7.5 (default, May 15 2013, 22:43:36) [MSC v.1500 32 bit (Intel)] on win32
Type "help", "copyright", "credits" or "license" for more information.
>>> 5 + 6
11
```

* Languages basics (syntax reference)

```
import MODULE
from MODULE import NAME


print EXPR


VAR = EXPR


if COND:
    SUITE
[elif COND:
    SUITE]
...
[else:
    SUITE]


for VAR in ITERABLE:
    SUITE
    [break]
    [continue]


while COND:
    SUITE
    [break]
    [continue]


try:
    SUITE
except EXCEPTION [as ex]:
    SUITE
...
[else:                      # code gets here only when there was no exception
    SUITE] 
[finally:                   # this code will always be performed
    SUITE]


raise EXCEPTION(...)


def NAME(a, b, c, ..., *args, **kwargs):     # *positional arguments and **keyword arguments
    SUITE
    [return EXPR]
    [yield EXPR]


class NAME([BASE, ...]):
    SUITE
```

* For people with a C background:
  * Python doesn't have ``do ... while`` (use ``while``) nor does it have ``switch`` (use ``if``s or 
     dispatch tables)
  * Assignment is a statement, **not an expression**. You cannot do ``if (a = foo()) == 5:``
  * There's no such thing as passing by-value. It's always by-reference.

* For people with a C++/Java background:
  * **Everything** is an object: integers, functions, types, etc.
  * There are no privates, only conventions. Members that start with ``_`` are not to be manipulated directly
  * There's no ``new``, just call the class like a function.

* Words of caution:
  * ``except MyException, YourException`` is **not what you have in mind**. You must use parenthesis here, e.g., 
    ``except (MyException, YourException) [as ex]`` 


## Rich Types ##

Python comes with lots of built-in types that you need to get acquainted with 

{% highlight pycon %}
>>> 5+3
8
>>> 27**63
1499398741586788200414239710724876101933611366003344657118522818557991334322919287339806483L
>>> 5+3j
(5+3j)
>>> 1/(5+3j)
(0.14705882352941177-0.08823529411764706j)
>>> [1,2,3]
[1, 2, 3]
>>> (1,2,3)
(1, 2, 3)
>>> d={"a":4, 7:()}
>>> d["a"]
4
>>> d[7]
()
>>> True, False, None
(True, False, None)
>>> set([2,6,2,7,2,8,6])
set([8, 2, 6, 7])
{% endhighlight %}

And string manipulation is a pleasure with Python 

{% highlight pycon %}
>>> "hello" + "world"
'helloworld'
>>> a="this is a single line string"
>>> a[5]
'i'
>>> a[5:12]
'is a si'
>>> a.upper()
'THIS IS A SINGLE LINE STRING'
>>> a.count("i")
5
>>> a.replace("i", "j")
'thjs js a sjngle ljne strjng'
>>> a.startswith("thi")
True
>>> "single" in a
True
>>> "multiple" in a
False
>>> a.split()
['this', 'is', 'a', 'single', 'line', 'string']
>>> a.split("i")
['th', 's ', 's a s', 'ngle l', 'ne str', 'ng']
{% endhighlight %}

String interpolation
{% highlight pycon %}
>>> "My name is %s. You %s, prepare to %s" % ("Inigo Montoya", "killed my father", "die")
'My name is Inigo Montoya. You killed my father, prepare to die'
>>> "My name is %03d" % (7,)
'My name is 007'
{% endhighlight %}

Multi-line strings
{% highlight pycon %}
>>> b="""this is
... a multi
... line string"""
>>> b
'this is\na multi\nline string'
>>> b.splitlines()
['this is', 'a multi', 'line string']
{% endhighlight %}


{% highlight pycon %}
>>> ", ".join(["hello", "long", "john"])
'hello, long, john'
{% endhighlight %}


## Useful Builtins ##

* help, dir, 
* int, str, 
* len, list, repr, type
* min, max, sum, sorted, all, any, 
* open, eval
* range, enumerate, xrange, zip,
* slicing, generators
 

{% highlight pycon %}

>>> a=[5,2,6,8,23,6,8,43,21,76]
>>> a.sort()
>>> a
[2, 5, 6, 6, 8, 8, 21, 23, 43, 76]
>>> a[3:6]
[6, 8, 8]
>>>


{% endhighlight %}

## Loopy De Loop ##

{% highlight pycon %}
>>> for i in range(4):
...     print i * 3
...
0
3
6
9
>>> [i * 3 for i in range(4)]
[0, 3, 6, 9]
>>> [i * 3 for i in range(4) if i % 2 == 0]
[0, 6]
{% endhighlight %}

## ¿Comprendes? ##


{% highlight pycon %}
>>> print "\n".join(" ".join("%3d" % (i * j,) for j in range(1,11)) for i in range(1,11))
  1   2   3   4   5   6   7   8   9  10
  2   4   6   8  10  12  14  16  18  20
  3   6   9  12  15  18  21  24  27  30
  4   8  12  16  20  24  28  32  36  40
  5  10  15  20  25  30  35  40  45  50
  6  12  18  24  30  36  42  48  54  60
  7  14  21  28  35  42  49  56  63  70
  8  16  24  32  40  48  56  64  72  80
  9  18  27  36  45  54  63  72  81  90
 10  20  30  40  50  60  70  80  90 100
{% endhighlight %}


## Execution Model ##

This might be too advanced for newcomers, but I find that explaining the mechanics helps people with previous 
programming background understand how the magic happens. So: the secret to the execution model is dictionaries.




## When in Doubt ##

{% highlight pycon %}
>>> import this
The Zen of Python, by Tim Peters

Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
If the implementation is easy to explain, it may be a good idea.
{% endhighlight %}


## And No Python Tutorial Can Go Without ##

<a href="http://xkcd.com/353/" title="Antigravity"><img src="http://tomerfiliba.com/static/res/2013-11-15-xkcd.png"></a>








