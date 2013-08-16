---
layout: blogpost
title: Hooking Imports for Fun and Profit
description: Introducing 'nimp' and some discussion on python's import mechanism
tags: [python]
---

I really love Python... it's so hackable that it just calls for hacking, inspiring your 
imagination to find ways to stretch its boundaries. This time I decided to investigate into 
[import hooks](http://www.python.org/dev/peps/pep-0302/), to add some missing functionality I 
wanted to have.

As you probably know, Python uses a *flat namespace* for packages, that works on a 
"first found first served" basis. Packages are simply searched in linear order, as they appear 
in `sys.path`: if two directories contain a package named `foo`, importing `foo` will fetch 
package in the first directory. This is normally the desired behavior (as it allows you to 
override some modules by changing `PYTHONPATH`), but it's also quite limiting. 

Consider the *nested package namespace* used by Java and various other languages (e.g., Haskell), 
where packages are normally "deeply nested", as in `com.sun.foo.bar` or `com.ibm.spam.ham`. 
In Haskell, for instance, packages are normally placed under their appropriate "categories", 
e.g., `Data.Vector` or `Control.Monad`. When you write a new data type, you'll probably put 
it under `Data`, as in `Data.Vector.UberVector`.

If we were to use something like that in Python, if would require us to have a single `com/` 
directory, under which lots of sub-packages must be placed. This might be possible, but it's 
certainly not the "right way"; and besides, it implies that code written by Sun and IBM is 
somehow related (after all, they share the `__init__.py` file in `com/`), which means one may 
affect the other (for better or worse :)).

It would make much more sense to have separately-installed packages, e.g., 
`site-packages/com.ibm.spam.ham` and `site-packages/com.sun.foo.bar`, where each package is 
independent of the other. Sure, they might share a common `com` prefix -- but that's all. 
This is especially useful in corporate environments, where multiple teams share common packages
(which usually get very unoriginal names, say, `common`), and name collisions are very likely. 
It's not a joke: at my work-place, we're know reorganizing our code after such problems. Also, 
from a marketing point-of-view, it might make more sense for your customers to 
`import mycompany.foobar` than just `import foobar`.

But most importantly -- it's *composable*. Nested packages allow you to "inject" your package
into another namespace. Take `twisted` for instance: it's become so large that it had made more 
sense to split it up into sub-packages (`twisted.conch`, `twisted.news`, ...), and allow 
end users to choose which of them they wish to install. However, since Python wouldn't let you have
`site-packages/twisted` and `site-packages/twisted-conch`, they resorted to hacking `distutils` 
into doing what they want. If nested packages were supported, you would have a core `twisted`
package, with separate add-on packages like `twisted-conch`. So why not, really?

Enter [nimp](http://pypi.python.org/pypi/nimp/) ("nested imports"). Without going into too many 
technical details, `nimp` is a *meta-import hook* -- it modifies the way `import` statements work. 
Specifically, it scans `sys.path` and "merges" packages that begin with a common prefix into 
"logical packages". For instance, if you have `com-ibm-foo` and `com-sun-bar` on your `sys.path`,
`nimp` will create *namespace packages* for `com`, `com.sun` and `com.ibm`. 
This would allow code like `import com.ibm.foo` or `from com.sun.bar import vodka` to work 
transparently. All you need to do is run `import nimp; nimp.install()` (you can also put it 
in your `site.py`, so it would happen every time you run a Python process), and you're ready to go.

This was the first time I wrote an import hook, and I really liked how I easy it was to change 
the import mechanism. So today I had another idea -- **lazy imports**. Of course there's 
[PEAK's lazyModule](http://peak.telecommunity.com/DevCenter/Importing#lazy-imports) and this 
[quite complicated recipe](http://code.activestate.com/recipes/473888-lazy-module-imports/),
but I thought, why not combine the two. Writing code like `from peak... import lazyModule; foo = lazyModule("foo")` 
is cumbersome, while the recipe attempts is too make everything lazy. 

Instead, I created a module called `__lazy__`, that when imported, installs a meta-import hook. 
This import hook handles only modules that begin with `__lazy__`, so instead of importing them, 
it returns an "on-demand-loaded module" (i.e., when you try to access an its attributes). 
Using it is really simple: 

{% highlight pycon %}
>>> from __lazy__ import telnetlib
>>> telnetlib
<OnDemandModule 'telnetlib'>
>>> telnetlib.Telnet  # forces loading
<class telnetlib.Telnet at 0x015B08B8>
>>> telnetlib
<module 'telnetlib' from 'C:\Python27\lib\telnetlib.pyc'>

>>> from __lazy__.xml.dom import minidom
>>> minidom
<OnDemandModule 'xml.dom.minidom'>
>>> minidom.parseString   # forces loading
<function parseString at 0x01659CF0>
>>> minidom
<module 'xml.dom.minidom' from 'C:\Python27\lib\xml\dom\minidom.pyc'>
{% endhighlight %}

Note, though, that using `from __lazy__.x.y import z` forces the loading of `x`, since we use the 
dot operator on it. The `from __lazy__ import foo` is "truly lazy"

You can get the code of `__lazy__` [here](https://gist.github.com/1030448).

