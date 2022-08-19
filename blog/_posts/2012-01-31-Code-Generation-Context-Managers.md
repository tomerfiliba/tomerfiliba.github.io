---
layout: blogpost
title: Code Generation using Context Managers
description: Introducing a code generation toolkit that achieves correlation between the
             generator code and the generated code, using context managers
tags: [python]
imageurl: /static/res/2012-01-31-code.jpg
---

When I was working on [Agnos](http://agnos.sourceforge.net), a cross-language RPC framework,
I had a lot of code-generation to do in a variety of languages (Python, Java, C#, and C++).
At the early stages, I just appended strings to a list. It was quick and dirty, and it's got the
job done... but that wasn't enough, of course. I've lost the original code already, but it looked
something like this:

{% highlight python %}
def generate_proxy(typeinfo):
    lines = [
        "public class %sProxy {" % (typeinfo.name,),
        "    private int uid;",
        "    public %sProxy(int uid) {" % (typeinfo.name,),
        "        this.uid = uid;",
        "    }",
    ]
    for attr in typeinfo.attributes:
        if attr.get:
            lines.append("    public %s get%s() {" % (attr.typename,
                                                    attr.name,))
            lines.append("        // ...")
            lines.append("    }")
        if attr.set:
            lines.append("    public void set%s(%s value) {" % (attr.name,
                                                            attr.typename))
            lines.append("        // ...")
            lines.append("    }")
    lines.append("}")
    return lines
# ...

lines = []
for ti in typeinfos:
    lines.extend(generate_proxy(m, ti))

open("foo.java").write("\n".join(lines))
{% endhighlight %}

There are several problems with this approach. First of all, it's very cumbersome and fragile.
If you forget a comma in the list, two adjacent strings will be concatenated. Also, you have
to do everything yourself, like remembering to close brackets, add semicolons, do the right
indentation, etc. If you wished to split this code into functions, the functions you call would
have to know the indentation level you're calling them at, or the generated code would be
unreadable. This might seem negligible, but think of languages where indentation matters, like
Python...

The fundamental problem with this approach (and similar ones) is that the **code generator does
not reflect the structure of the generated code**. The two are diseparate, while it's quite
obvious they should be correlated.

In order to solve this, I turned to [context managers](http://www.python.org/dev/peps/pep-0343/),
a feature I highly value. Conceptually, context managers provide a way to bind beginning-and-end
into a single entity; this is normally used for resource management -- but we can leverage this
construction further (I'll this review in a different post). Here, I've used them to create
*nested blocks*, which allowed me to reflect the structure of the generated code in the code
generator.

Without going into too many details, I defined a `Module` class that exposes a `block()`
context manager and a `stmt()` function. The module holds a "stack" of blocks, and entering a new
block pushes a it onto the stack. Statements are then appended to the topmost block on the stack.
Now, because this framework is "language-aware", it can encapsulate language-specific details.
For instance, In Java, a block will be indented correctly and wrapped by brackets; in Python,
we'll append colons to the opening line and indent the block; in C++, if the block begins with
`class`, `struct` or `enum`, we'll append a trailing semicolon as well.

Here's how it works:

{% highlight python %}
m = JavaModule()
m.stmt("import foo")
m.stmt("import bar")
m.sep()   # an empty line

#...

def generate_proxy(m, typeinfo):
    BLOCK = m.block
    STMT = m.stmt

    with BLOCK("public class {0}Proxy", typeinfo.name):
        STMT("private int uid")
        with BLOCK("public {0}Proxy(int uid)", typeinfo.name):
            STMT("this.uid = uid")

        for attr in typeinfo.attributes:
            if attr.get:
                with BLOCK("public {0} get{1}()", attr.typename, attr.name):
                    pass
            if attr.set:
                with BLOCK("public void set{0}({1} value)", attr.name,
                                                            attr.typename):
                    pass
# ...

for ti in typeinfos:
    generate_proxy(m, ti)

m.render_to_file("foo.java")
{% endhighlight %}

So what have we gained?

*   The code is much shorter and more concise
*   Brackets, semicolons and indentation come out-of-the-box
*   We're no longer working with flat lists of strings -- we're working with hierarchal entities
    that reflect the structure of the generated code
*   And the other way around -- the structure of the generated code is reflected in the generating
    code; nested code is indeed nested inside `BLOCK`s, thus the "generatee" and generator are
    **visually and semantically correlated**.
*   We can easily split our code into functions, as the module maintains an internal stack.
    If `f()` opened a block and called `g()` under it, it the code that `g()` generates will be
    placed and indented correctly.

I tried to keep my code quite general, so I haven't defined all of the target language's
constructs, but of course we could do that, or at least head in that direction.
It might look like this:

{% highlight python %}
def generate_proxy(m, typeinfo):
    with m.CLASS(typeinfo.name + "Proxy", ["public"]):
        m.FIELD("int", "uid", ["private"])
        with m.CTOR(["int uid"]):   # CTOR gets the name of the current class
            STMT("this.uid = uid")
{% endhighlight %}

However, there's a question of where we "put our foot down", or we'll end up writing *Java
Combinators for Python*... and then we'll be writing Java in Python. No need for that,
thank you very much.

The full source code can be found in the
[Agnos repository](https://github.com/tomerfiliba/agnos/blob/master/compiler/src/agnos_compiler/langs/clike.py)
