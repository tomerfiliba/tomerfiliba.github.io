---
layout: blogpost
title: "Splitbrain Python"
tags: [rpyc, python]
description: "Simultaneously load multiple instances of the same modules into one process"
---

<img src="http://rpyc.sourceforge.net/_static/rpyc3-logo-medium.png" title="RPyC logo" class="blog-post-image" />

I was working together with [Shay Berman](https://github.com/shay-berman) on a distributed 
test-automation solution on top of RPyC, when this idea struck me. The design calls for a "master"
machine and several slave machines, where the test actually *runs* on the master, but "interfaces
with reality" on slaves. This basically means we use the master's CPU and memory, but everything
IO-related takes place on the slaves -- by monkey-patching Python's interfaces with the OS to
operate over RPyC on slaves.

To illustrate what we were after, suppose we have machine A, which hosts our test, and machine B,
which is connected to the necessary testing equipment (hardware). The test was first designed to
run directly on machine B, so it imports ``os`` and ``subprocess`` to spawn local processes
or read files and devices. Right after importing the test (and any of the modules it uses) on 
machine A, but before executing it, we connect to machine B and go over all the modules in 
``sys.modules``. We then monkey-patch each module that imported ``os``, ``subprocess``, and some
other modules with their RPyC counterparts. Now when the test runs and calls (for instance) 
``os.getcwd()``, it actually invokes ``conn_to_machine_b.modules["os"].getcwd()``.

A more elegant way to do this is pass the RPyC connection to the test -- this way, the test would 
use ``self.conn.modules["os"].getcwd()``, where ``conn`` would either be an RPyC connection
to the slave, or a fake connection that represents the local host, if the test is to run locally. 
If it were only refactoring tests, I'd vote for the elegant way -- but the tests themselves rely
on a stack of libraries that interface with the OS, and updating all of them is out of the 
question.

So I thought my solution was perfect for the task, until I realized that some code may need to run
on the host machine (master), and some tests require multiple slaves. However, Python only loads
modules once, which means we can't have several versions, each patched to a different slave.
We need a split-brain Python.

## Enter Splitbrain ##

[Splitbrain](https://github.com/tomerfiliba/rpyc/tree/master/experimental) is a very early,
*experimental* feature that I hope to incorporate into the next release of RPyC. At first I tried
to use [Py_NewInterpreter](http://docs.python.org/c-api/init.html#Py_NewInterpreter), which
creates a somewhat-isolated sub-interpreter with a separate copy of ``sys.modules``. However, 
calling ``Py_NewInterpreter`` from within ``PyEval_EvalFrameEx`` (i.e., via the interpreter
instead of via C extensions) proved flaky... the interpreter makes all sorts of assertions that 
just stop holding once we swap the interpreter's thread state. Boo hoo.

The solution I ended up with basically reimplements ``Py_NewInterpreter`` using 
[Cython](http://www.cython.org/), without swapping the 
[interpreter state](http://hg.python.org/cpython/file/a4d5ac78a76b/Include/pystate.h#l15): when 
switching to a new interpreter, it saves the interpreter's ``builtins``, ``sysdict`` and 
``modules`` and replaces them with fresh copies. When switching back, it restores the old dicts.
It's buggy, subject to change, not meant for the faint of heart -- but heck, it works!

By the way -- Cython folks -- 
[pyximport](http://docs.cython.org/src/userguide/tutorial.html#pyximport-cython-compilation-the-easy-way) 
is priceless!

## A Sketch ##

{% highlight python %}
import rpyc

conn_win = rpyc.classic.connect("windows-box")
conn_lin = rpyc.classic.connect("linux-box")

slave_win = rpyc.Splitbrain(conn_win)
slave_lin = rpyc.Splitbrain(conn_lin)

# local `subprocess` module
from subprocess import Popen

with slave_win:
    # this is windows-box's `Popen`
    from subprocess import Popen
    
    proc = Popen(["c:\\Windows\\system32\\net", "view"])
    out, err = proc.communicate()

with slave_lin:
    # this is linux-box's `Popen`
    from subprocess import Popen
    
    proc = Popen("/bin/ls")
    out, err = proc.communicate()

{% endhighlight %}


