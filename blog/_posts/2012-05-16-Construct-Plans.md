---
layout: blogpost
title: The Future of Construct
tags: [construct]
description: Discussing future plans for Construct
---

<img src="http://tomerfiliba.com/static/res/2012-05-16-construct-logo-small.png" title="Construct" style="float:right" width="250px" />

It's been a long while since I've put time into [Construct](http://construct.wikispaces.com).
I gave up on it somewhere in 2007, right after the release of v2.0... I think I just got bored, 
and felt like the library was complete and extensible enough to survive on its own. Of course 
I was wrong there, and code-rot had spread all over.

Luckily for us, [Corbin Simpson](https://github.com/MostAwesomeDude/) took up the project in 
January of 2011 and has been maintaining it since then. He migrated it to github, changed the 
project to use a proper directory structure, fixed lots of bugs, and wrote 
[extensive documentation](http://construct.readthedocs.org/en/latest/). Since then, Construct 
has been building a solid community and has reached quite a remarkable number of downloads on PyPI. 

All this time, I've been busy with my other projects, but I kept toying with the idea of 
*Construct 3*. I got some sketches, wrote some early drafts, cleaned up the implementation of 
Construct's core... but it's remained a dream. A couple of months ago I decided I'd back-port a 
nice feature from Construct 3, called 
[this expressions](https://github.com/construct/construct/commit/969e5685ce7251af49c9e267a732b63bcea4e278),
and it has rekindled my interest in the library. 

`This` Expressions
------------------
One of the goals of Construct 3 was to generate efficient (C/Python) code from construct definitions.
It even worked, to some extent: for instance, see [this snippet](http://sebulbasvn.googlecode.com/svn/trunk/ccon/test.py) 
that automatically generates [this C-code](http://sebulbasvn.googlecode.com/svn/trunk/ccon/moshe.c). 
I had no recollection of this [until I discovered it today](https://github.com/MostAwesomeDude/construct/pull/20#issuecomment-5727638).
Funny.

Anyway, Construct 2 uses ``lambda`` functions to represent dependencies between constructs, e.g.

{% highlight python %}
s = Struct("LV",
    UBInt8("length"),
    Bytes("value", lambda ctx: ctx["length"]),
)
{% endhighlight %}

and since this is the case, it's impossible to translate dependencies to C. So I've created the 
``this`` object, which essentially **builds** an expression tree from native Python expressions.
In order to evaluate the expression, you simply invoke it with a context: 

{% highlight pycon %}
>>> from construct import this
>>> this.x * 2 + 3
((this.x * 2) + 3)
>>> (this.x * 2 + 3)({"x":7})
17
{% endhighlight %}

So now we can replace all ``lambda ctx: ctx["foo"]`` by the more succinct and readble ``this.foo`` --
the benefits are visually clear -- but they go even deeper than this: since we're no longer 
dealing with **black-box** lambda functions, we can drill down into them and generate the 
appropriate (static) code. 

Construct 2.5
-------------
I had to do some Construct work recently, and I missed the conciseness of ``this`` expressions,
so I took the time to back-port them to Construct 2. I sent a pull request to Corbin, but he's 
a bit too busy to maintain the library on a regular basis now, so he's created a github 
*organization* and [moved the repository to there](https://github.com/construct/construct); 
this is where Construct will be developed from now on.

Tinkering with the old code again got me sentimental, and I started to do some long-awaited 
maintenance. I plan to release version 2.5 (note the dramatic shift from 2.06 to 2.5) in the summer 
(say August), and here's the list of planned changes:

* Adding ``this`` expressions
* Dropping ``construct.text`` -- it's always been an experimental feature and it's achingly 
  inefficient. If you want to parse **grammars**, you should use 
  [more adequate tools](http://wiki.python.org/moin/LanguageParsing)
* Adding Python 3 support (based on the work of [Eli Bendersky](https://github.com/MostAwesomeDude/construct/pull/19));
  the library will support Python 2.5-3.2, using ``six``
* General cleanups and optimizations
* Closing the *wikispaces* site in favor of *readthedocs*

Construct 3
-----------
The *next big thing(TM)*, [Construct 3](https://github.com/tomerfiliba/construct3), is still far away.
I've got lots of cool ideas, but time is too short (as so is my ability to concentrate on one thing).
Generally, the guiding thought is to **modernize the library** and make it even yet more compact 
and efficient, while removing magic along the way. For instance, because ``Structs`` require their 
sub-elements to have a name, and due to the fact keyword-arguments in Python are unordered, 
all constructs ended up taking a name argument (even though it's usually meaningless to them, 
as in ``UBInt8("length")``). This has given birth to all sorts of bastards like ``Rename`` and 
``Alias``; from now on, it'll be simpler:

{% highlight python %}
s = Struct(
    Member("length", UBInt8),
    Member("value", Bytes(this.length)),
)
{% endhighlight %}

A second issue is, laying the grounds for **code generation**, thus converting all dependencies 
to use ``this`` expressions, and perhaps even limiting the power of ``Adapters``. Or at least, 
making a clear distinction between the constructs that can be turned into code and those that can't.

And last but not least, I want Construct 3 to come with a **designer**, where you would drag-and-drop 
constructs, group them in "boxes", connect them to each other (instead of ``this.length``, you'd 
connect the Bytes' ``count`` field to the source construct), etc. And most importantly, you could
try it out live on a data sample, and see how it breaks it up. I made this sketch here (click to 
download the PowerPoint slides) to demonstrate how it might look:

<a href="http://tomerfiliba.com/static/res/2012-05-16-sketch.ppt">
<img src="http://tomerfiliba.com/static/res/2012-05-16-designer.png" title="Construct Designer" width="580px" />
</a>

I think it would be very powerful.

Closing Words
-------------
I'm mainly writing this post to inform everyone of Construct's [new repository](https://github.com/construct/construct),
and to **ask for feedback** on the plans for v2.5... Any thoughts, requests, comments would be
appreciated. Also, if anyone wants to join in (especially with Construct 3 ambitious plans) -- 
feel free to contact me.


