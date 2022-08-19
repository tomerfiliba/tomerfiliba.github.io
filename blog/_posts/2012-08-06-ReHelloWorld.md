---
layout: blogpost
title: "ReHelloWorld"
description: "New site design and a heartwarming Windows story"
imagepreview: /static/res/2012-08-06-windows.png
---

Tada! The new design is here. The previous one was based on some Drupal theme I once used
(before moving to *github pages*) that I tried to mimic when I barely new CSS. Over the past
eight months it just grew, patch by patch, until it became an inconsistent conglomerate. The new
site is inspired by the clean minimalism of sites like [this](http://daltoncaldwell.com/)
(of [svbtle](https://svbtle.com/) fame), attempting to reduce visual clutter and offer a more
coherent theme that reacts nicely to screens of all sizes (try to resize the browser to see).
If you have any feedback or insights, please share them in the comments below -- it's a work
in progress and I'd love to improve.

I'm still working on the last installment of the *Javaism, Exceptions and Logging* series,
but I'm buried in work on University projects (my [watermarking](/blog/ReedSolo)
project turned out quite interesting, I'll elaborate on it when I get the chance) and my
day job, so it'll have to wait.

## A Windows Story ##

<img src="/static/res/2012-08-06-windows.png" class="blog-post-image" />

Instead, I wanted to share a debugging experience I had today at work (together with the excellent
[@RoyRothenberg](https://twitter.com/RoyRothenberg)) of an enigmatic bug that appeared all of the
sudden when we added support for Windows 2012. Generally speaking, our product wraps one of the
darkest corners of operating systems: low level SCSI stuff that connects storage arrays and hosts.
It's never a pleasant sight, what goes on there, but the voodoo that goes on on Windows will
surely turn me religious one day.

The problem was simple: we tried to send a SCSI inquiry to a certain device (which used to work),
but we got ``Errno 6: Invalid Handle``. It happened only the first time we tried to send the
inquiry -- all future attempts worked like charm, and it only happened on Windows 2012 64bit. The
problem was highly consistent: open a Python interpreter, the first inquiry fails, the following
ones work; open up a fresh interpreter and it reproduces.

Our gut feeling was, "okay, they fucked something up on Windows 2012 -- let's just put a retry
loop", but that didn't help at all. Any number of resend attempts failed with the same error, even
when we added a short sleep in between. Once we got back to the interactive interpreter and called
the function again - it worked, from that point on.

Puzzled, we stuck a ``code.interact()`` inside the resend loop; the first attempt failed,
the interactive prompt showed and we terminated it by ``Ctrl+Z`` (not typing anything else).
Once we did that, the second retry attempt magically worked. But it got even more bizarre:
we moved the ``code.interact()`` *before* any inquiry attempts... it popped up, we terminated it,
and then the **first** inquiry attempt worked out of the box.

We came to the conclusion that we had some sort of memory corruption going on, and that some of
field in our ``ctype`` structs must be misaligned. We've seen this kind of behavior before when
memory corruption was involved. But the MSDN told us everything was of the right type and
alignment... In a desperate move, we zeroed the buffer that was passed to the kernel. This time,
the first attempt failed with ``Invalid Handle``, while the second failed with ``Invalid
Parameter`` -- so the first attempt didn't even get to the point of looking at the input buffer!
Alas, it wasn't memory corruption after all! We felt hopeless.

After some mindstorming, we got suspicious of ``win32file`` and ``ctypes`` and went on to inspect
very closely how they handled their parameters. A tedious investigation revealed that the code
invoked ``DeviceIoControl`` (obtained via ``ctypes.windll.kernel32``) without setting the
function's ``argtypes``, so ctypes just had to guess. Everything was fine, except for the
first argument, the device handle, which was treated as a ``DWORD`` for being an integer.

The problem is, ``HANDLE`` is not a numeric type but rather a disguised ``void`` pointer, so
it's 8-bytes wide on 64bit platforms. When the kernel read in the arguments ctypes had placed on
the stack, it took the first and half of the second for the handle, which obviously turned to
be an invalid one.

This, by itself, makes perfect sense, and should have happened every time. In fact, had it happened
every time, it would have been obvious... but what on earth could ever explain the strange
phenomena we've seen? How could it ever have worked the second time (with the very same arguments)?!
If the size of the first argument is wrong, all following ones are garbage. Does the kernel *learn*
that our process mistakenly passed a 32bit handle? Does ctypes *come to the conclusion* that the
first integer argument should actually be treated as a ``HANDLE`` instead of a ``DWORD`` --
after seeing ``Errno 6``? Is that the most sophisticated form of machine-learning ever seen, or what?
And it all happens inside the kernel or an FFI library? And how the hell does invoking
``code.interact()`` *before anything took place*, could have averted the problem?! And how come it
never happened on previous versions of 64bit Windows (with the same version of Python and ctypes)?

Windows, you bewilder me.
