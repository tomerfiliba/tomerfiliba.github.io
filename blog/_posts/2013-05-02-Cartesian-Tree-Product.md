---
layout: blogpost
title: "Cartesian Products of Trees"
draft: true
description: "Producing all possibilities (Cartesian product) of expression trees"
---

I have to admit that my day-to-day life involves very little algorithmic problems, but here and
there I get a chance to think. In this post, I'd like to discuss a funny problem that I've met 
several times already in my programming career, each time in different circumstances.
In lack of a better name, I call it "Cartesian Product of Trees", and here's how it goes:

Say you're given an [expression tree](http://en.wikipedia.org/wiki/Binary_expression_tree). To 
limit the scope of the problem, we'll assume the tree is binary, its internal nodes can either be  
`AND` or `OR`, and its leaves hold "atomic comparators" (which are of no interest to us). 
Here's an example expression:

    (x=5 OR y=6) AND z=7

Which is represented by the following expression tree:

        AND
        /  \
       OR   \ 
      /  \   \
    x=5  y=6  z=7

Now the problem is to produce all different sub-trees such that:
 * Each sub-tree consists only of `AND` internal nodes
 * Each sub-tree satisfies the original expression (any assignment that satisfies a sub-tree 
   must also satisfy the original tree)
 * `OR`-ing all the sub-trees produces a tree that is mathematically-equivalent to the original one
   (any assignment that satisfies the original tree must satisfy the reconstructed tree)

In other words, we want to produce all partial expressions of the original expression, which 
will satisfy it, and which can together reconstruct it. Big words aside, here's what we want:

    x=5 AND z=7
    y=6 AND z=7

Each of expression here satisfies the original one (try it), and if we OR the two, we get a 
mathematically-equivalent tree:

    (x=5 AND z=7) OR (y=6 AND z=7)
    
    
           OR
          /  \
         /    \
      AND      AND
     /   \    /   \
    x=5  z=7 y=6  z=7

If you take a second look, it resembles Cartesian products where some "joints" (nodes) in the tree 
duplicate the resulting tree, and it grows very fast as well. For instance, if we take 
`(x=5 OR y=6) AND (z=7 OR w=8)`, we'll get 4 sub-trees 
    
    x=5 AND z=7
    x=5 AND w=8
    y=6 AND z=7
    y=6 AND w=8

However, it depends on the structure of the tree; `(x=5 OR y=6 OR z=7) AND w=8` produces 3 sub-trees.
This closely relates to the [rules of distributivity](http://en.wikipedia.org/wiki/Distributive_law)
in propositional logic, but it seems to me that the "Cartesian product" notion is a generalization 
of which.

## How is it Useful? ##

Since we're dealing with expression trees, it's hardly surprising that the two times I had to 
use this algorithm related to syntax. In the first case, I wrote a [fuzz-testing](http://en.wikipedia.org/wiki/Fuzz_testing)
tool for an interactive program, like the MySQL shell. The program accepted commands, conforming to
a well-defined syntax, and I wanted to generate commands at random and see that it doesn't crash.

For instance, a command might look like `map-lun <vol-name|vol-id> lun-id` and we'll want to try
both variants, i.e., `map-lun vol-name lun-id` and `map-lun vol-id lun-id`. Of course the syntax
is generally much more complex, with nested brackets, optional arguments, etc. In short, it 
gets interesting.

Another real-life use case is running queries against a huge dataset. In order not to complicate 
our query engine (written in C for performance), it can perform only intersections (ANDs) of filters. 
If you want to query for more complex conditions, you have to run it multiple times with the 
partial queries and "sum up" the results. But we don't want the end user "doing the math" for us,
and waiting for one query to finish before we start the next means we have to load data from the
store multiple times. If we could process it in chunks, we'd benefit from cache locality.

## The Algorithm ##

The code is strikingly short, but that's not to mean that it's easy to follow. It relies on
two recursively-nested for-loops: 

{% highlight python %}
def cartesian_tree_product(node):
    if not isinstance(node, tuple):
        yield node
        return
    
    lhs, op, rhs = node
    for l in set(cartesian_tree_product(lhs)):
        for r in set(cartesian_tree_product(rhs)):
            if op == "|":
                yield l
                yield r
            else:
                yield (l, op, r)
{% endhighlight %}

Let's try it out on the expression `(x=5 OR y=6) AND (z=7 OR w=8 OR q=9) AND r=10`:

{% highlight pycon %}
>>> exp = ((("x=5", "|", "y=6"), "&", (("z=7", "|", "w=8"), "|", "q=9")), "&", "r=10")
>>>
>>> for v in set(cartesian_tree_product(exp)):
...     print v
...
(('x=5', '&', 'z=7'), '&', 'r=10')
(('y=6', '&', 'w=8'), '&', 'r=10')
(('y=6', '&', 'z=7'), '&', 'r=10')
(('x=5', '&', 'w=8'), '&', 'r=10')
(('y=6', '&', 'q=9'), '&', 'r=10')
(('x=5', '&', 'q=9'), '&', 'r=10')
{% endhighlight %}

Does the trick.

Trying to estimate the complexity of this beast may be futile, but it clearly seems to be 
doing "more work" than a "simple" [SAT](http://en.wikipedia.org/wiki/Boolean_satisfiability_problem)
problem: it doesn't just find one satisfying assignment, it looks for all satisfying assignments!
This ought to put it in the NP-hard class. In fact, if we generate an binary expression of 
alternating AND's and OR's, we can get much worse than exponentiation!

Here's a little function that generates an interleaved binary expression:

{% highlight python %}
counter = itertools.count()
def mkexp(n):
    if n == 0:
        return "x%d" % (counter.next(),)
    return (mkexp(n-1), "&" if n % 2 == 0 else "|", mkexp(n-1))
{% endhighlight %}

E.g., 

{% highlight pycon %}
>>> mkexp(4)
(((('x0', '|', 'x1'), '&', ('x2', '|', 'x3')), '|', (('x4', '|', 'x5'), '&', ('x6', '|', 'x7'))), 
'&', ((('x8', '|', 'x9'), '&', ('x10', '|', 'x11')), '|', (('x12', '|', 'x13'), '&', ('x14', '|', 'x15'))))
{% endhighlight %}

Now

{% highlight pycon %}
>>> for i in range(1, 10):
...     exp = mkexp(i)
...     variants = set(cartesian_tree_product(exp))
...     print i, len(variants)
...
1 2
2 4
3 8
4 64
5 128
6 16384
^C
{% endhighlight %}

Notice how each step either doubles or squares the number of results... that's because AND's and 
OR's are interleaved (AND's double, OR's square). Seems more like a 
[power tower](http://en.wikipedia.org/wiki/Tetration) to me. 

## Extension: the Inverse Problem ##
The inverse problem is also useful. In the inverse problem we're given a set of expressions and
we're trying to generate the most "compact form", i.e., "undo the effects" of the 
distributivity law.

I once wrote a test harness, where each test specified its prerequisites declaratively. For instance,
a test might need to run after the system had come up from an emergency shutdown, so the framework 
would bring the system to the required state and then then run the test. Obviously, it may take
a while to bring the system to a certain state. It could range from minutes to days. And we have 
hundreds of tests!

Here we are given a test suite (list of tests) and we want to find the most efficient order to run
the entire suite. This means we want to minimize the setup and teardown times when moving between
different system states.

{% highlight python %}
class FooTest:
    REQUIRES = [A, B, C]
    
    def test(self):
        # ...

class BarTest:
    REQUIRES = [A, B, D]

    def test(self):
        # ...

class SpamTest:
    REQUIRES = [A, D]

    def test(self):
        # ...


{% endhighlight %}

So here, we can first bring the system to state A and B (e.g., running over 10 hours and having 
less than 1 TB of free space), then setup C, run `FooTest`, teardown state C and setup state D,
run BarTest, teardown B and run SpamTest.

In essence, we want to take the requirement lists from each test and reconstruct the most 
compact tree that represents them. Then we follow that tree in BFS order and save time.

        A
       / \
      B   \
     / \   \
    C   D   D

It took me a while to realize it's basically the inverse of the original problem, but when I did,
it only seemed natural.




