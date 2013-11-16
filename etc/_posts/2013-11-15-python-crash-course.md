---
layout: etc-page
title: A Python Crash Course for the Statically Typed Programmer
draft: true
description: Python crash-course
imageurl: http://tomerfiliba.com/static/res/2013-11-15-biglogo.png
imagelink: http://www.python.org/
---

<style type="text/css">break{display:block;height:0px;margin: 130px 80px;border-top: 5px dashed rgba(100,100,100,0.2);}</style>

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

<break/>

You'll see inheritance and class diagrams along side with constructs imported from Haskell and LISP.

Python is dynamically-typed (as opposed to statically-typed) but has strong-typing 
(as opposed to Perl or Javascript) 

<img src="http://tomerfiliba.com/static/res/2013-11-15-perl.png">

<break/>

Syntax reference (1)

```
# printing to stdout
print EXPR

# assignment
VAR = EXPR

# conditions
if COND:
    SUITE
[elif COND:
    SUITE]
...
[else:
    SUITE]

# for-loops
for VAR in ITERABLE:
    SUITE
    [break]
    [continue]

# while-loops
while COND:
    SUITE
    [break]
    [continue]
```

<break/>

Syntax reference (2)

```
# try-except
try:
    SUITE
except EXCEPTION [as ex]:
    SUITE
...
[else:                      # iff there was no exception
    SUITE]
[finally:                   # always be performed
    SUITE]

# raising exceptions
raise EXCEPTION(...)

# importing modules or attributes
import MODULE
from MODULE import NAME

# defining functions
def NAME([a, [b, ...]]):
    SUITE
    [return EXPR]
    [yield EXPR]

# defining classes
class NAME([BASE, [...]]):
    SUITE
```

<break/>

The interactive interpreter is your friend! I mapped ``F11`` on my keyboard to fire up an interpreter... 
it's better than any calculator you'll ever have

```
$ python
Python 2.7.5 (default, May 15 2013, 22:43:36) [MSC v.1500 32 bit (Intel)] on win32
Type "help", "copyright", "credits" or "license" for more information.
>>> 5 + 6
11
```
<break/>

For people with a C background:
* Python doesn't have ``do-while`` (use ``while``) nor does it have ``switch`` (use ``if``s or 
   dispatch tables)
* Assignment is a statement, **not an expression**. 
  * You cannot write ``if (a = foo()) == 5:``
* There's no such thing as passing by-value. It's always by-reference.

For people with a C++/Java background:
* **Everything** is a first-class object
  * Integers, functions, types, stack frames, tracebacks, etc.
* There are no privates, only conventions. Members that start with ``_`` are not to be manipulated directly.
* There's no ``new``, just *invokes* the class like a function.

<break/>

Python comes with lots of useful built-in types

{% highlight pycon %}
>>> 5+3
8
>>> 27**63
149939874158678820041423971072487610193361136600
3344657118522818557991334322919287339806483L
>>> 5+3j
(5+3j)
>>> 1/(5+3j)
(0.14705882352941177-0.08823529411764706j)
>>> [1,2,3]
[1, 2, 3]
>>> [1,2,3] + [4,5,6]
[1, 2, 3, 4, 5, 6]
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

<break/>

String manipulation is a pleasure with Python 

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

<break/>

Encoding strings like a boss

{% highlight pycon %}
>>> "hello".encode("hex")
'68656c6c6f'
>>> "hello".encode("utf16")
'\xff\xfeh\x00e\x00l\x00l\x00o\x00'
>>> "hello".encode("zlib")
'x\x9c\xcbH\xcd\xc9\xc9\x07\x00\x06,\x02\x15'
{% endhighlight %}

String interpolation

{% highlight pycon %}
>>> "My name is %s. You %s, prepare to %s" % ("Inigo Montoya", 
... "killed my father", "die")
'My name is Inigo Montoya. You killed my father, prepare to die'
>>>
>>> "My name is %03d" % (7,)
'My name is 007'
{% endhighlight %}

And joining strings is surprisingly useful

{% highlight pycon %}
>>> ":".join(["AA", "BB", "CC"])
'AA:BB:CC'
{% endhighlight %}

<break/>

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

<break/>

If I had time to show you only three functions, they will be ``help()``, ``dir()`` and ``type()``.
Everything else you can discover on your own.

{% highlight pycon %}
>>> help
Type help() for interactive help, or help(object) for help about object.
>>> dir()
['__builtins__', '__doc__', '__name__', '__package__']

>>> help(dir)
    dir([object]) -> list of strings

    If called without an argument, return the names in the current scope.
    Else, return an alphabetized list of names comprising (some of) the attributes

>>> dir("hello")
['__add__', '__class__', '__contains__', '__delattr__', '__doc__', '__eq__', '__for
_mod__', '__mul__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__',
nter', 'count', 'decode', 'encode', 'endswith', 'expandtabs', 'find', 'format', 'in
index', 'rjust', 'rpartition', 'rsplit', 'rstrip', 'split', 'splitlines', 'startswi']

>>> type(5)
<type 'int'>
>>> type("hello")
<type 'str'>
{% endhighlight %}

<break/>

Next, let's meet some types and learn how to convert (not **cast**) values from one type to the other

{% highlight pycon %}
>>> int
<type 'int'>
>>> str
<type 'str'>
>>> list
<type 'list'>

>>> int(5.1)
5
>>> int("5")
5
>>> str(5)
'5'
>>> list("hello")
['h', 'e', 'l', 'l', 'o']
{% endhighlight %}

<break/>

Types matter

{% highlight pycon %}
>>> 5 + "6"
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
TypeError: unsupported operand type(s) for +: 'int' and 'str'
>>> 5 + int("6")
11
>>> str(5) + "6"
'56'
{% endhighlight %}

Repr(esenation)

{% highlight pycon %}
>>> repr(5)
'5'
>>> repr("hello")
"'hello'"
>>> print "Hello %s" % ("foo\n\tbar",)
Hello foo
        bar
>>> print "Hello %r" % ("foo\n\tbar",)
Hello 'foo\n\tbar'
{% endhighlight %}

<break/>

Lists

{% highlight pycon %}
>>> range(10)
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
>>> range(10,20)
[10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
>>> range(10,20,2)
[10, 12, 14, 16, 18]
>>> range(20,10,-2)
[20, 18, 16, 14, 12]
>>> len([2,5,2,6,2,6])
6
>>> len("hello")
5
>>> a=[2,5,2,6,2,6]
>>> max(a)
6
>>> min(a)
2
>>> b=["what", "is", "this", "thing"]
>>> max(b)
'what'
>>> max(b, key = len)
'thing'
{% endhighlight %}

<break/>

Slicing

{% highlight pycon %}
>>> a=range(10,20)
>>> a[0]
10
>>> a[-1]
19
>>> a[3:7]
[13, 14, 15, 16]
>>> a[7:]
[17, 18, 19]
>>> a[-3:]
[17, 18, 19]
>>> a[:-3]
[10, 11, 12, 13, 14, 15, 16]
{% endhighlight %}

<break/>

Lambda functions

{% highlight pycon %}
>>> lambda x: x * 2
<function <lambda> at 0x0297EEB0>
>>> f = lambda x: x * 2
>>> f(6)
12
>>> map(f, range(10))
[0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
>>> filter(lambda x: x % 2 == 0, range(10))
[0, 2, 4, 6, 8]
{% endhighlight %}

<break/>

Working with files

{% highlight pycon %}
>>> f = open("/etc/profile")
>>> f.read(100)
'# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))\n# and Bourne compatible shell'
>>> f.readline()
's (bash(1), ksh(1), ash(1), ...).\n'
>>> f.readline()
'\n'
>>> f.readline()
'if [ "$PS1" ]; then\n'
>>> list(f)[:4]
['  if [ "$BASH" ] && [ "$BASH" != "/bin/sh" ]; then\n', 
 '    # The file bash.bashrc already sets the default PS1.\n', 
 "    # PS1='\\h:\\w\\$ '\n", 
 '    if [ -f /etc/bash.bashrc ]; then\n']
{% endhighlight %}

<break/>

## ¿Comprendes? ##

Remember ``map`` and ``filter``? Well, it's time to forget them

{% highlight pycon %}
>>> [x for x in range(10)]
[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
>>> [x * 2 for x in range(10)]
[0, 2, 4, 6, 8, 10, 12, 14, 16, 18]
>>> [x for x in range(10) if x % 2 == 0]
[0, 2, 4, 6, 8]
>>> [x * 2 for x in range(10) if x % 2 == 0]
[0, 4, 8, 12, 16]
{% endhighlight %}

<break/>

Comprehensions galore!

{% highlight pycon %}
>>> [i * j for i in range(1,5) for j in range(1,5)]
[1, 2, 3, 4, 2, 4, 6, 8, 3, 6, 9, 12, 4, 8, 12, 16]
>>> [[i * j for i in range(1,5)] for j in range(1,5)]
[[1, 2, 3, 4], [2, 4, 6, 8], [3, 6, 9, 12], [4, 8, 12, 16]]
>>> [" ".join(["%3d" % (i * j,) for i in range(1,5)]) for j in range(1,5)]
['  1   2   3   4', '  2   4   6   8', '  3   6   9  12', '  4   8  12  16']
>>> print "\n".join([" ".join(["%3d" % (i * j,) for i in range(1,11)]) for j in range(1,11)])
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

<break/>



* enumerate, xrange, zip, generators



> Skills: How to read a traceback
>
>
>
>
>


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

## Execution Model ##

This might be too advanced for newcomers, but I find that explaining the mechanics helps people with previous 
programming background understand how the magic happens. So: the secret to the execution model is dictionaries.

Python is an interpreted language. Code is evaluated when the module is imported

And No Python Tutorial Can Go Without

<a href="http://xkcd.com/353/" title="Antigravity"><img src="http://tomerfiliba.com/static/res/2013-11-15-xkcd.png"></a>

When in Doubt

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

<break/>

<img src="http://tomerfiliba.com/static/res/2013-11-15-iknow.jpg">






