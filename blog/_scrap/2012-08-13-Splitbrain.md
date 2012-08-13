---
layout: blogpost
title: "Split-brain Python"
tags: [rpyc, python]
description: "Monkey-patching platform-specific modules over RPyC. Step 3: World domination"
---

<img src="http://rpyc.sourceforge.net/_static/rpyc3-logo-medium.png" title="RPyC logo" class="blog-post-image" />

I was working together with a colleague on a complex distributed test-automation solution on top 
of RPyC, and we looked for a way to make our existing codebase RPyC-friendly (without altering it).
The design of the framework called for a master machine and several slave machines, such that 
the test actually *runs* on the master, but "interfaces with reality" on the slave. Basically, we
wanted the test to use the master's CPU, but perform all IO-related actions on its slave.

To illustrate this, suppose we have machine A, which runs our test, and machine B, which is 
connected to the necessary hardware and testing equipment. The test was initially designed to run 
directly on machine B, so it imports modules like ``os`` and ``subprocess`` and uses them to
manipulate the machine. We now want the test to run on machine A - but keep using machine B's
``os`` and ``subprocess`` modules, so whenever it spawns child processes or open device files, 
it would take place on machine B. This allows us to reboot the machine during tests, or even 
use Eclipse's debugger to run debug the test locally.

## Enter Split-brain ##
The better-design approach would be to pass the RPyC connection as an argument to all functions;
however, this is not practical as it requires adapting ~50,000 lines of code. The more practical 
way is to *monkey-patch* every module that imports a platform-specific module, and replace that
module with its remote counterpart. But this is not so simple either, as we may have several
slaves and multiple threads... since Python loads modules only once, monkey-patching a module
makes the change apparent to everyone.

What we're basically after is a *split-brain Python*, i.e., support multiple instances of the 
same modules simultaneously, so that you could patch one without affecting the others. At first,
I tried using [Py_NewInterpreter](http://docs.python.org/c-api/init.html#Py_NewInterpreter), which
provides this mechanism, but it's not possible to use it from within ``PyEval_EvalFrameEx`` --
you can safely use it only from extension modules. After some failed but very interesting 
experiments, I decided to go pure-Python and implemented 
[splitbrain.py](https://github.com/tomerfiliba/rpyc/blob/master/rpyc/utils/splitbrain.py).  
But enough with the talk -- here's some code.

## A Sketch ##

{% highlight pycon %}
>>> import rpyc
>>> from rpyc.utils.splitbrain import patch, Splitbrain
>>> patch()
>>>
>>> import platform
>>> platform.platform()
'Linux-2.6.38-15-generic-i686-with-Ubuntu-11.04-natty'
>>> 
>>> winmachine = Splitbrain(rpyc.classic.connect("my.windows.box"))
>>> 
>>> with winmachine:
...     print platform.platform()
... 
Windows-XP-5.1.2600-SP3
>>>
>>> platform.platform()
'Linux-2.6.38-15-generic-i686-with-Ubuntu-11.04-natty'
>>> 
>>> import win32file
Traceback (most recent call last):
  ...
ImportError: No module named win32file
>>> with winmachine:
...     import win32file
...     print win32file.CreateFile
... 
<built-in function CreateFile>
>>> 
>>> win32file.CreateFile
Traceback (most recent call last):
  ...
AttributeError: 'NoneType' object has no attribute 'CreateFile'
{% endhighlight %}

**Note**: ``splitbrain`` is currently *experimental* and has some known issues. I hope to
stabilize it and incorporate it into the next release of RPyC (3.3). Meanwhile you can experiment 
with it and open bug reports on github.


