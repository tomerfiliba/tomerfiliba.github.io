---
layout: blogpost
title: Solving Systems of Linear Equations
tags: [python]
description: A simple and complete solver for systems of linear equations
imageurl: https://www.tomerfiliba.com/static/res/2012-03-25-gauss.png
imagetitle: Carl Friedrich
---

Yet another university-related post, but I really enjoyed it so I thought I'd share: for a GUI-
workshop I'm taking, we are given GUI-layout constraints as a system of linear equations, which
we need to satisfy. To make life more interesting, some constraints are constant while some are
parametric. There's no magic here, just some linear algebra combined with Python's overloadable
nature to produce a nice and compact solver for these linear systems.

Naturally, you present your system as a *coefficient matrix*, which is Gauss-eliminated and then
"solved" for a given set of variables. I took the Gauss-Jordan elimination code from
[Jarno Elonen](http://elonen.iki.fi/code/misc-notes/python-gaussj/index.html) and modified it to
support MxN matrices (not necessarily square). Here's a simple example of elimination:

{% highlight pycon %}
>>> m = Matrix([1,2,4,2], [3,7,6,8], [2,2,2,9])
>>> print m.eliminate()
( 1.00  -0.00   0.00   6.00)
( 0.00   1.00  -0.00  -1.00)
( 0.00   0.00   1.00  -0.50)
{% endhighlight %}

But of course a reduced row-echelon matrix is not our final goal - we want to get the variable
*assignments*. For this, we have `solve()`:

{% highlight pycon %}
>>> sol = solve(m, ["x", "y", "z"])
>>> print sol
{'y': -1.0000000000000004, 'x': 6.0, 'z': -0.4999999999999998}
{% endhighlight %}

Modulo precision errors, we get `x = 6`, `y = -1` and `z = -0.5`. If we have more equations than
variables, the "extraneous" equations must be linear combinations of previous ones, or a
contradiction will result. But what if we have less equations than variables? It means we have
some *degrees of freedom*... how would we handle that? It's actually simple - instead of being
resolved to constant values, variables will be assigned *dependent expressions*:

{% highlight pycon %}
>>> m2 = Matrix([1,2,4,2], [3,7,6,8])
>>> print m2.eliminate()
( 1.00   0.00   16.00  -2.00)
( 0.00   1.00  -6.00   2.00)
>>>
>>>
>>> sol = solve(m2, ["x", "y", "z"])
>>> print sol
{'y': <BinExpr (2.0 - (-6.0 * z))>, 'x': <BinExpr (-2.0 - (16.0 * z))>,
    'z': <FreeVar z>}
{% endhighlight %}

As you can see now, `z` is a *free variable* and `x` and `y` are *dependent* on it. Of course more
than one variable may be free and some variables may be independent of free variables. Once a value
for `z` is known, we can "fully evaluate" the dependent expressions:

{% highlight pycon %}
>>> sol["x"].eval({"z" : 10})
-162.0
{% endhighlight %}

The code is available on my [github page](https://github.com/tomerfiliba/tau/blob/850ff76bf59c80cd9eb18100986205276125508e/sadna/linear_solver.py).
Note: all numbers are represented as `Decimals`, to avoid loss of precision as much as possible,
and I'm using an "epsilon" value of `1E-20` to equate numbers to each other (meaning, `x == y` iff
`abs(x-y) <= epsilon`).
