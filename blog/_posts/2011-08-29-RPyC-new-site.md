---
layout: blogpost
title: RPyC Moves to a New Site 
---

RPyC is in the process of migrating from <http://rpyc.wikidot.com> to it's new (and hopefully final) 
location at <http://rpyc.sourceforge.net>. Wikidot had served us well, and was easy to maintain, 
but they started displaying way to many ads and didn't support `rsync` or `SSH` access, 
which meant I couldn't upload the generated API reference automatically. 

The new site is written entirely in ReST using [sphinx](http://sphinx.pocoo.org/) and large parts 
of it are auto-generated from docstrings in the source code. It's all now part of the 
[git repository](http://http://github.com/tomerfiliba/rpyc), and I only have to run 
`make upload` to upload it all up.

