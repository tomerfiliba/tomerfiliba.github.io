---
layout: blogpost
title: Some Notes on RPyC 3.2.x
tags: [rpyc]
description: The (unplanned) development of RPyC 3.2.3 
imageurl: http://rpyc.readthedocs.org/en/latest/_static/banner.png
imagetitle: RPyC
---

As I said in the previous blog post, I hoped for v3.2.2 to be the last release of the 3.2 line... 
Naturally, I was wrong :) Turns out the fix for 
[issue #76](https://github.com/tomerfiliba/rpyc/issues/76>) was buggy, and I decided to finally 
remove the use of excepthooks in favor of taking care of remote traceback chaining in the
exception class' ``__str__`` method itself. The tentative release date for the release is 
August 1st, and I really hope to end the 3.2 line here.

I created a branch called ``LTS3.2`` which will be used only for back-porting bug fixes from
the ``master`` branch, which has now become the development branch of 3.3. I rebased ``master``
on top of ``LTS3.2`` now, so that the two would have linear histories, which of course resulted
in a forced update, so anyone who was using master for development would now have to do 
``git fetch origin; git reset --hard origin/master`` instead of a simple ``git pull``.
It's not supposed to happen again, sorry.

There shouldn't be any more features in v3.2.3, so the development would take place on ``master``,
from which I'll cherry-pick bug fixes onto LTS3.2. That's all for now... 