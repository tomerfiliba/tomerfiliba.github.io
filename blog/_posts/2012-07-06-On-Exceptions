---
layout: blogpost
title: "Javaism, Exceptions, and Logging: Part 2"
description: "Javaism, Exceptions and Logging: Lessons from refactoring large codebases. Part 2 of 3"
draft: true
---

<img src="http://tomerfiliba.com/static/res/2012-07-06-i-fixed2.jpg" class="blog_post_image" title="Nesting Exceptions..." />

Considering the reactions to the [previous post](http://tomerfiliba.com/static/Javaism) in this 
series, my intent was obviously misunderstood and I take the blame for that. Please allow me to 
clarify that **I was not attacking Java or Python**: Java is popular and has proven to be productive, 
both as a language and as an ecosystem; the stylistic and semantics choices it makes are none of my 
concerns (although I must admit I'm not a big fan). And as for Python, I was only saying that it
**copied Java's implementation** (nearly one-to-one) in some modules (and I think I've shown that
pretty well in the last post). I said that it's silly, because **Python is not subject to the same 
limitations** that Java has, which dictate how the Java implementation looks and works. I'm not 
going to open the discussion over whether OOP is good or bad, or mixins vs. interfaces, etc. -- 
I'm simply saying that "Java concepts" (which I called *Javaisms*) seem to enter Python **for no 
good reason**. Meaning, in Python we have better (more Pythonic) ways to do it. I hope the scope 
of my discussion is clear now.

## When Life Serves You Lemons ##

In this installment, I'm going to discuss how to **properly work with exceptions**, based on my long 
experience with large-scale Python projects. In fact, this series was born after I got frustrated 
with the code quality of a certain library that my team develops, the details of which aren't really 
relevant. Naturally I can't include code snippets here, and a detailed examination of each would 
make this post endless; instead, I wish to share a some representative examples that I encountered:

* I used a function in the spirit of ``open_device(devfile)``, and passed a nonexistent device file 
  (for testing purposes or by mistake), say, ``"/dev/nonexistent"``. The underlying error is 
  obviously ``IOError(ENOENT)``, but what I got back is a cryptic ``DeviceError``.

* I called ``get_device_info()`` and it simply returned ``None``. Digging into the code, it
  turned out this function catches ``DeviceError`` and returns ``None`` in this case. 
  Further investigation showed that my machine had installed on it a more recent version of a 
  dependency, in which some method's name had changed. At some point (deep into the stack), the 
  code used ``except Exception`` (which, of course, swallowed this ``AttributeError``) and 
  translated it into a ``DeviceError``.

* I called a function such as ``enumerate_all_devices()`` and it returned an empty list.
  At first I was told "Of course, this library isn't supposed to work on Ubuntu, only on RHEL". 
  Further (and very tedious) investigation showed it just needs to run as ``root``. 

This kind of stuff happens to me every time I get to an unexplored corner of the code, I'm not 
kidding. I've already devised a method for debugging it: I comment-out all exception handling code 
in any function along the way, until I find the actual error -- which is basically the treatment 
that I'm about to suggest here: 

> **The first rule of exception handling is: Don't handle exceptions**

## Do Not Catch Broadly ##

I believe this bullet point is very obvious in theory but not-so-obvious in practice: **always catch
only the most-derived/most-specific exception**. Many times, the number of possible erroneous 
cases is large and their handling is similar... Another issue is programmer's laziness: you have to 
*import the specific exception* class from this library you're using, and you might not feel like 
reading docs or code just to find that one exception. It also exposes you to implementation detail,
which you normally wish to avoid. Just as well, that library you're using might not be perfect 
either -- perhaps they use many exceptions that don't derive from one common base class.
All in all, you might have attenuating circumstances, but try to stick to this rule as much as 
possible. 

On the other hand, **never use an empty** ``except:``

{% highlight python %}
try:
    ...
except:
    ...
{% endhighlight %}

Such an ``except`` clause will catch **all exceptions**, including ``SystemExit`` and 
``KeyboardInterrupt``. So unless you plan to loose the ability to Ctrl-C a running program, or
even terminate it gracefully, take the extra step and use ``except Exception:``.

## Do Not Be Overprotective ##

A tendency I find in many programmers is being overprotective towards their users, to the points 
where it seems like paternalism. It's as if they try to "take care of everything that might go 
wrong", so the user "won't have to deal with anything bad"... sounds childish, I know.

When I pass a filename to a function, and that function can't open the file for whatever reason,
there's no need to *mask out* the underlying ``IOError`` in favor of a user-friendlier 
``FileDoesNotExistError`` -- as the saying goes, **"we're all consenting adults here"**. You should
expect your users (programmers) to have sufficient background as a prerequisite. He/she shouln't 
have to be kernel hackers just to open a file, but they surely should know what ``ENOENT`` or 
``EPERM`` are (or be able to look them up). The "raw" ``IOError`` looks like

    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
    IOError: [Errno 2] No such file or directory: '/dev/nonexistent'

and anyone with common sense would be able to cope with it. 

Put it differently, ask yourself what **useful information** are you adding here? How does a
``FileDoesNotExistError`` help the user (again, a programmer) solve the issue better? You're only 
adding clutter: now he/she would have to **catch both** ``FileDoesNotExistError`` and 
``IOError`` -- you might have dealt with ``ENOENT``, but what about ``EPERM`` or ``EISDIR``?
The error message already includes all the required information, you have nothing to add to that;
so instead of treating your user like a baby -- just propagate the "scary" ``IOError`` up.

I must this phenomena virtually doesn't exist in open-source code, but in closed-source projects 
I find it all over the place: I'd guess corporate-employed programmers make the worst parents :)

### A Note On Real Users ###

A question then arises: **what about non-programmer end-users?** What if my product's a GUI and 
a nasty stack trace suddenly shows up?

Well, first of all, this rule only deals with **libraries**, or products whose end users are 
programmers. But on second thought, what does it matter? If you're going to pop up an error box
to the screen, saying "No such file or directory", does it really matter if it's an ``IOError`` or
a ``FileDoesNotExistError``? Either way, you log the traceback to a file and show a message box 
to informs the user of the issue and ask him/her what to do. What's the added value?

Then again, when it comes to non-programmers, I don't want to get into generalizations. They might
as well **not be** consenting adults...

## Do Not Wrap Exceptions ##

Until Python 3, raising an exception during the handling of one meant the original traceback
was lost. This has been finally solved, but Python 2.x still accounts for the majority of the code 
base. 


## Do not Handle Exceptions ###








## On the Granularity of Exception Classes ##

Some people follow a rather laconic methodology of throwing a single exception class with a 
different message (string) every time. Heck, I even found people who were too lazy to define their 
own exception class, so they just raise ``Exception`` directly (or worse, ``RuntimeError``!). Then,
in case you wish to handle specific exceptions, you need to ``except Exception`` and inspect
the exception object... this brings up memories of the dreaded string exceptions. We're passed 
that! Defining an exception class is a one-liner: ``class MyException(Exception): pass``, so
don't be lazy.

Others go in the opposite direction and define very specific exception classes for every single
case. You end up with a huge hierarchy of exceptions, and after a while, you can't even remember 
which exception you should use in this case or that case. You might even end up with 
logically-overlapping exceptions -- I've seen this happen.

As a rule of thumb, the granularity of exception classes should match the granularity at which
exception handling is done. If you can handle ``ConnectionError`` differently from 
``InvalidCredentials``, it means the two are disparate: for the first, you'd display an error 
message, but for the second, you may prompt the user to enter his/her credentials once more. 
On the other hand, if there's no reason to handle ``ConnectionFailedServerNotListeningOnPort`` 
differently from ``ConnectioFailedServerCrashed``, why make them separate classes? A single 
``ConnectionError`` is good enough, and the application may either abort upon receiving it,
or attempt to reconnect. **Note:** of course the message may (and should) be different in each
case, but it's only meaningful for logging/diagnostic purposes.

At any point you think of defining a custom exception class, ask yourself:

1. Is there already a good-enough standard exception? Many times ``TypeError`` or ``ValueError``
   make sense. For instance, if your function only takes strings of even length, a ``ValueError`` 
   seems legit. On the other hand, don't be lazy! 
2. Will I (or my users) wish to handle this exception differently from a broader one? Would they
   be able to *act differently* on ``XError`` than on ``YError``? 


