---
layout: blogpost
title: Toying with Context Managers
description: Highlights some rather surprising use-cases of context managers
tags: [python]
---

As I promised in the [code-generation context managers post](http://tomerfiliba.com/blog/Code-Generation-Context-Managers),
I wanted to review some more, rather surprising, examples where context managers prove very handy.
So we all know we can use context managers for resource life-time management: before entering the
`with`-suite we allocate (open) the resource, and when we leave the suite, we free (close) it --
but there's much more to context managers than meets the eye.

## Stacks, for Fun and Profit ##
We've seen this one in the code-generation post, but we can generalize this notion a bit. Every time
we enter a `with`, we'd append an element to a list, which we'd pop on exit. Consider this snippet:

{% highlight python %}
class Stacking(object):
    def __init__(self):
        self.stack = []
    @contextmanager
    def foo(self):
        self.stack.append("foo")
        yield "bar"
        self.stack.pop(-1)
{% endhighlight %}

Nothing fancy, but that's exactly how the code generation framework works: whenever you enter a new
block, it's pushed onto the "stack", and whenever we leave the block, the top-of-stack element is 
popped. This is how we take care of indentation, curly-braces, etc.

But of course this pattern is much more useful. Consider something like this:

{% highlight python %}
class Env(object):
    def __init__(self):
        self._envstack = [os.environ]
    @contextmanager
    def new(self, **kwargs):
        self._envstack.append(self._envstack[-1].copy())
        self._envstack[-1].update(kwargs)
        yield
        self._envstack.pop(-1)
env = Env()

with env.new(PATH = "/tmp/foo/bin", SHELL = "zsh"):
    # processes created here will use the modified environment
{% endhighlight %}

We can also leverage this concept to run commands as different users. Here's a sketch:

{% highlight python %}
cmd.run("ls")                       # as current user
with cmd.as_user("root"):
    cmd.run("ls", "/proc")          # as `root`
    with cmd.as_user("mallory"):
        cmd.run("rm", "-rf", "/")   # as `mallory`
    cmd.run("cat", "/etc/passwd")   # back as `root` again
{% endhighlight %}

In essence, every time you want to make temporary/local changes or change the 

## Contextbacks ##
Many times it's useful to pass two functions
Context-backs (an extension of 'callbacks') are 


## Lightweight Asynchronism ##







