---
layout: blogpost
title: "Splitbrain Python"
tags: [rpyc, python]
description: "Monkey-patching platform-specific modules over RPyC, so that code can temporarily run on remote"
---

<a href="http://rpyc.sf.net"><img src="http://rpyc.sourceforge.net/_static/rpyc3-logo-medium.png" title="RPyC logo" class="blog-post-image" /></a>

I was working together with a colleague on a complex distributed test-automation solution on top 
of [RPyC](http://rpyc.sf.net), and we looked for a way to make our existing codebase RPyC-friendly 
(without altering it). The design of the test framework called for a master machine and several 
slave machines, such that tests actually *run* on the master, but "interface with reality" on the 
slaves. Basically, we wanted the test to use the master's CPU (and development environment), but 
perform all IO-related actions on its slaves.

To illustrate this, suppose we have machine A, which runs our test, and machine B, which is 
connected to the necessary hardware and testing equipment. The test was initially designed to run 
directly on machine B, so it imports modules like ``os`` and ``subprocess`` and uses them to
manipulate the machine. We now want the test to run on machine A - but keep using machine B's
``os`` and ``subprocess`` modules, so whenever we spawn child processes or open device files, 
it would actually take place on machine B. This allows us to reboot machine B as a part of a 
test, or even use *your-favorite-IDE-here* to run test and debug it locally.

If it were only tests, RPyC already enables us to do that: we'd use ``conn.modules.os`` and
``conn.modules.subprocess`` instead of their local counterparts. However, the test themselves
rely on a several libraries that expect to run locally, and provide services for the test. For 
instance, these libraries manipulate the operating system's storage stack, to map and mount
volumes. Changing these libraries to run over RPyC is not an option (tens of thousands of LoC
that handle low-level OS-specific tools)... 

## Enter Splitbrain ##

So this is the background that had given birth to 
[splitbrain](https://github.com/tomerfiliba/rpyc/blob/master/rpyc/utils/splitbrain.py): instead
of changing our codebase to use RPyC -- why not use RPyC to monkey-patch our codebase? When
``splitbrain`` is enabled (usually within a ``with`` block), all of Python's interfaces with the
operating system (``os``, ``platform``, ``subprocess``, ...) are patched to go through RPyC, so 
that any code that runs at this point "believes" it actually runs directly on the remote machine.
It's easier than it seems, actually.

First, we import RPyC and install ``splitbrain``:
{% highlight pycon %}
>>> import rpyc
>>> from rpyc.utils.splitbrain import patch, Splitbrain
>>>
>>> # monkey-patch all OS-APIs
>>> patch()
{% endhighlight %}

Next, just to prove a point, we're running on a Linux box:
{% highlight pycon %}
>>> import platform
>>> platform.platform()
'Linux-2.6.38-15-generic-i686-with-Ubuntu-11.04-natty'
>>> import sys
>>> sys.platform
'linux2'
{% endhighlight %}

Let's now connect to a remote machine over RPyC and enter a  ``splitbrain`` context:
{% highlight pycon %}
>>> winmachine = Splitbrain(rpyc.classic.connect("my.windows.box"))
>>> with winmachine:
...     print platform.platform()
...     print sys.platform
... 
Windows-XP-5.1.2600-SP3
win32
{% endhighlight %}

When we're out of the ``splitbrain`` context, everything is back to normal again:
{% highlight pycon %}
>>> sys.platform
'linux2'
>>>
>>> import win32file
Traceback (most recent call last):
  ...
ImportError: No module named win32file
{% endhighlight %}

And inside a ``splitbrain`` context, when a module is not found locally it's fetched from the
remote machine!
{% highlight pycon %}
>>> with winmachine:
...     import win32file
...     print win32file.CreateFile
... 
<built-in function CreateFile>
>>> 
>>> win32file.CreateFile
Traceback (most recent call last):
  ...
AttributeError: Nonexistent module win32file (CreateFile)
{% endhighlight %}

**Note**: ``splitbrain`` is still *highly experimental* and probably has issues with multiple threads. 
I hope to stabilize it and incorporate it into the next release of RPyC (3.3). In the meanwhile,
you can experiment with it on RPyC's master branch and report bugs on github. It's likely it will 
never be perfect, but heck, it's cool!



