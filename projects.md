---
layout: default
section: projects
title: Projects
description: A list of my active and inactive projects
---

## Ongoing Projects ##

* [RPyC](http://rpyc.sf.net) - *Remote Python Call*, a transparent and symmetric RPC 
  framework for python, which can work either in service-oriented mode or 
  "contract-less" mode, where there's no predefined contract between the two parties. 
  RPyC excels in testing environments, where it enables you to keep the test logic located in 
  a central point, while allowing it to run on multiple systems and platforms.

* [Construct](http://construct.wikispaces.com) - **Declarative** data-structure definition library,
  where complex constructs can be defined in terms of simpler ones. Since the data structure
  is declarative rather than procedural, it can be used for both parsing ("unpacking") and
  building ("packing"), making the library symmetric.

* [Plumbum](http://plumbum.readthedocs.com) - *Shell combinators*, local and remote 
  command execution, and a programmatic CLI (handling of command-line switches) toolkit

* [Agnos](http://agnos.sf.net) - The *Agnostic RPC framework*: a statically-generated 
  cross-language RPC, with support for object proxying

## Research/Toy Projects ##

* [Reedsolo](http://pypi.python.org/pypi/reedsolo) - A pure-python Reed-Solomon (error-correcting 
  code) codec; more info [on the blog post](http://tomerfiliba.com/blog/ReedSolo). 

* [Microactor](https://github.com/tomerfiliba/microactor) - A micro-reactor framework that makes 
  use of coroutines instead of callbacks. Similar to 
  [multitask](http://code.google.com/p/python-multitask/) or 
  [cogen](http://code.google.com/p/cogen/)

* [Layer 5](https://github.com/tomerfiliba/layer5) - "The Fifth Layer" of the protocol stack: a 
  network layer that's logically placed on top of layer 4 (TCP) and takes care of negotiations, 
  versioning, reconnects, security, timeouts, etc. -- all in one place, instead of having each 
  application handle it on its own.

## Scraps ##

* [Nimp](https://github.com/tomerfiliba/nimp) - *Nested Imports* for python; a small module
  that enabled the use of java-style namespace-packages; note that similar functionality
  can be achieved by stdlib modules

* [sock2](https://github.com/tomerfiliba/sock2) - A pythonic, object-oriented replacement for the 
  `socket` module, providing much better and consistent APIs. No longer developed.

* [Minima](https://github.com/tomerfiliba/minima) - A minimalist web framework. The idea was
  "noSQL + noHTML + noJavaScript", but I abandoned it at the moment in favor of github pages :)

* [Conso](https://github.com/tomerfiliba/conso) - Quite a declarative console UI library
  (e.g. ncurses), in which you build the UI programmatically and the layout happens on its own.
  Not in a good shape.

* [Passover](https://github.com/tomerfiliba/passover) - A high-performance python tracer 
  (the tracing part worked great, but I never got to writing a decent trace reader, so it's quite
  useless this way). Requires Linux (nasty mmap tricks) on x86/64 (uses high-performance a timer).

