---
layout: blogpost
title: "Loads of Plumbum"
tags: [python]
description: "Plumbum (shell combinators library) has got many new features"
imageurl: /static/res/2012-05-12-plumbum.png
imagetitle: Plumbum
imagelink: http://plumbum.readthedocs.org/
---

It's kind of funny how things turn out. I haven't done any work on [Plumbum](http://plumbum.readthedocs.org/)
almost since it was released, back in May, and all of the sudden everything's happening at fast pace.
So version 1.0 was released earlier this month, followed by
[1.0.1](https://github.com/tomerfiliba/plumbum/blob/master/CHANGELOG.rst), which has added support
for [PuTTY](http://www.chiark.greenend.org.uk/~sgtatham/putty/) on Windows boxes and various other
bug fixes, and now I'm happy to announce that version 1.1 is just around the corner (scheduled for
mid-November). This release will add [Paramiko](https://github.com/paramiko/paramiko) support.

So far Plumbum relied on an external SSH client being installed, which it spawned every time you
wanted to run a remote process. This approach was easy, but it suffered from the high overhead of
setting up a new SSH connection every time (key-exchange, etc.). Using Paramiko, Plumbum now creates
a single socket connection over which it spawns processes in separate *channels* (a feature of SSH)
- so although we're dealing with a pure-Python implementation of SSH, it's considerably faster
when multiple remote processes are used. And, as a bonus, we get cheap socket forwarding - we
simply set up a ``direct-tcpip`` channel (that behaves like a regular socket), which is securely
tunneled over the underlying SSH transport.

This easily integrates with [RPyC](http://rpyc.sf.net): just run an RPyC server on a remote machine,
binding to ``localhost`` (so it won't accept external connections). Then, create a ``ParamikoMachine``
instance, connected to that host (passing in a keyfile or password if necessary), and call the
``connect_sock`` method of that object. Here's an example:

{% highlight pycon %}
>>> import rpyc
>>> from plumbum.paramiko_machine import ParamikoMachine
>>>
>>> m = ParamikoMachine("192.168.1.143")
>>> # connects to 192.168.1.143:18812 over SSH
... conn = rpyc.classic.connect_stream(rpyc.SocketStream(m.connect_sock(18812)))
>>> conn.modules.sys.platform
'linux2'
>>> m.close()
>>> conn.modules.sys.platform
Traceback (most recent call last):
  ...
EOFError: [Errno 9] Bad file descriptor
{% endhighlight %}

Keep in mind that these interfaces are unstable and may change before the official release. Moreover,
RPyC 3.3 is likely to add some sort of built-in support for that, something along the lines of
``rpyc.classic.connect_paramiko(mach, port)``.
