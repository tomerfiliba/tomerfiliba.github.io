---
layout: blogpost
title: Toying with Context Managers
description: Highlights some rather surprising use-cases of context managers
tags: [python]
imageurl: /static/res/2012-02-27-context.jpg
imagetitle: Very Demotivational
---

As I promised in the [code-generation using context managers post](/blog/Code-Generation-Context-Managers),
I wanted to review some more, rather surprising, examples where context managers prove handy.
So we all know we can use context managers for resource life-time management: before entering the
`with`-suite we allocate (open) the resource, and when we leave the suite, we free (close) it --
but there's much more to context managers than meets the eye.

### Stacks, for Fun and Profit ###

We've seen this one in the code-generation post, but we can generalize this notion a bit. Every time
we enter a `with` block, we'd append an element to a list, which we'd pop on exit. Consider this
snippet:

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
popped. This is how we automatically take care of indentation, curly-braces, etc.

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
    pass
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

In essence, every time you want to make local/undoable changes to your state, this pattern proves
helpful.

### Contextbacks ###

*Contextbacks*, a pun on *callbacks*, are contexts you pass as arguments to other functions. Many
times it's useful to pass a before-function and an after-function, and contextbacks are a nice
way to encapsulate this. So instead of this:

{% highlight python %}
def f(beforefunc, afterfunc):
    beforefunc()
    # your code goes here
    afterfunc()
{% endhighlight %}

You get this:
{% highlight python %}
def f(ctxback):
    with ctxback:
        # you code goes here
        pass
{% endhighlight %}

Not a ground-breaking change, but I prefer it as it's more concise.

### Lightweight Asynchronism ###

This is probably my favorite use case for contexts: you can use them to *pipeline* or *interleave*
long-lasting tasks. You can think of contexts are degenerate forms of [coroutines](http://en.wikipedia.org/wiki/Coroutine),
in which you have defined beginning and end, but the middle part is interchangeable, so you can
stick anything into it.

Imagine you need to format a harddisk (using `mkfs`) or perform some long network operation (like
copying a huge file over `scp`). The pattern is as follows: initiate the operation, wait for it
to finish, and either return or raise an exception. This fits perfectly well with the way contexts
work -- with one change -- `yield` instead of waiting.

{% highlight python %}
@contextmanager
def format_disk(devfile):
    proc = Popen(["/sbin/mkfs", "-t", "ext3", devfile])
    try:
        yield
    except Exception:
        proc.kill()
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise FormattingFailed(stderr)

with format_disk("/dev/sda1"), format_disk("/dev/sdb1"):
    pass
{% endhighlight %}

This saves you time: instead of waiting for the first operation to finish before starting with the
second, you can run them in parallel. The total time would be that of the longest task (not taking
into account the IO bottleneck). You can throw a `yield` into any piece of code instead of just
blocking, and use it as a pipelined contextmanager. You can copy three files in parallel, without
resorting to threads or a reactor in the background.

Of course you could improve that by returning an object that reports the progress of the
operation, e.g.

{% highlight python %}
with format_disk("/dev/sda1") as d1, format_disk("/dev/sdb1") as d2:
    while not d1.is_done() or not d2.is_done():
        print "%s is being formatted, %d%% completed" % (d1.devfile,
                d1.get_progress())
        print "%s is being formatted, %d%% completed" % (d2.devfile,
                d2.get_progress())
{% endhighlight %}

And voila! You have a thread-less, light-weight asynchronous framework at hand... a bit like
using a reactor, but without rewriting your code.

And last, if you can't tweak the blocking parts of the code (e.g., third party libraries), you can
use the "defer to thread" or "defer to process" approach, a la [twisted](http://twistedmatrix.com/trac/):

{% highlight python %}
@contextmanager
def defer_to_thread(func):
    thd = Thread(target = func)  # it would be smarter to use a
    thd.start()                  # thread-pool
    yield thd
    thd.join()

with defer_to_thread(task1), defer_to_thread(task2), defer_to_thread(task3):
    # do something else in the meanwhile
    pass
{% endhighlight %}

So that's all I had in mind. If you have other unorthodox use cases for contexts, I'd love to
hear about them!
