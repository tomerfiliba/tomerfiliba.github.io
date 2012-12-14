---
layout: blogpost
title: "New Experiences"
description: "Becoming an entrepreneur"
---

<a href="http://fakegrimlock.com/">
<img src="http://tomerfiliba.com/static/res/2012-12-15-grimlock2.png" class="blog-post-image" title="BECAUSE AWESOME"/></a>

Okay, I've been slacking off and I feel I've got some explaining to do... Allow me to start by
admitting that I lied. If you remember, I said [I wanted an easy life](http://tomerfiliba.com/blog/New-Beginnings/), 
but then the opportunity came and I knew I had to take it: I've joined two friends to co-found 
[Touchbase](http://www.touchbase.it/). Yes, I said it won't happen to me, but heck, it did.

At Touchbase, we plan to **revolutionize the calendar** - this outdated table that you use every day
to manage your time. You see, it turns out that even though hundreds of millions of people 
world-wide run their lives according to this naive table, it hasn't really changed much in the 
last couple of centuries: it's just a passive, linear representation of time, into which *you* 
insert events.

We believe people spend way too much time *managing their time*. In other words, you *work for your 
calendar* instead of it working for you. Think of how much time people spend *coordinating 
meetings*... If both you and the person you wish to meet with work at the same place (or share 
calendars), you can normally see each other's free/busy times. This makes finding a suitable time 
for you two a bit easier, but as you don't see event details, **you can't make informed decisions**.

For instance, your friend might have an out-of-town meeting from 9am to 11am, so picking a time slot
right at 11am isn't a good idea. Or, she might be on a business trip; she won't block her whole 
day as she still wants people to book with her at her destination, but how would you know that?
And the other way around - suppose you and this Tech guru will both be in New York next week, 
but neither one of you knows about the other being there. So instead of grabbing a coffee at a
Starbucks next week, you'll have to take a flight to California three weeks from now.

And we've only talked about one-on-one meetings. I suppose you know how frustrating is
coordinating a meeting of five people (even in the same office), or handling the reschedules/
counters that follow it. We aim high, both technologically (and algorithmically) and product-wise,
but we're starting out with more modest go-to-market strategies. 

## Lessons on Web Programming ##
In case you've been reading my blog, you probably know by now that I'm no fan of web programming. 
I always feel it's a conglomerate of unrelated or inferior technologies, hastefully stacked one 
on the other. That's not to say that people don't do amazing stuff on the web, but the foundations 
of it all are shaky.  

Part of our job at Touchbase it to handle large amounts of user data, which we obtain from third-
party providers. It works 98% percent of the time, but every once in a while we get timeouts or
malformed data, which aborts the user's request. In case the user's data is somehow malformed
(e.g., an expected field is missing in one record), subsequent retries would fail just the same, 
leading to user frustration. At some point it came to me that web programming is actually a 
stochastic process, not a deterministic one like most software development we're used to. We work 
with big numbers here, where the occasional anomaly should just be ignored. Many "best practices"
simply don't apply here and one has to resort to *wishful thinking*. In other words, do whatever
you can, ignore errors and learn to live with partial data. 

I brought this realization to the mighty @FAKEGRIMLOCK, and he explained: 

<a href="https://twitter.com/FAKEGRIMLOCK/status/276686347270500353">
<img src="http://tomerfiliba.com/static/res/2012-12-15-onerror.png" class="blog-post-image"/></a>

I'm an enlightened person now.

## In Other News ##

I just released [Plumbum v1.1](http://plumbum.readthedocs.org) today, adding 
[Paramiko integration](http://plumbum.readthedocs.org/en/latest/remote.html#paramiko-machine)
and [Subcommand support](http://plumbum.readthedocs.org/en/latest/cli.html#sub-commands). As usual,
the [changelog](http://plumbum.readthedocs.org/en/latest/changelog.html) holds the full details. 
I plan to write a short tutorial on subcommands soon, so stay tuned.

