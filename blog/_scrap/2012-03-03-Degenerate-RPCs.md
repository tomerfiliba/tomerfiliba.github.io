---
layout: blogpost
title: Degenerate RPCs
description: Virtually all communication protocols are degenerate forms of RPC; so why not
             abandon them in favor of a single "5th layer"?
published: false
---

I talked the other day with a friend of mine who's into web development. At some point he said
he found HTTP to be good enough a protocol, which has sparked a long discussion that I promised
I'd summaries in a blog post. So here I am now, a man of my word.

<img src="https://www.tomerfiliba.com/static/res/2012-02-17-http.jpg" style="float: right; with: 250px" />

I've been thinking about the subject of network protocols for some time now. It all began when
I started working on [RPyC](http://rpys.sf.net) some six years ago; since then I've become
"a man of many RPCs", which, I have to admit, is quite lame, but I think it has given me a very
deep insight on the subject. And I'll start right up by saying

## Everything is RPC ##

There, I've said it. Virtually **all network protocols** are but **degenerate forms of RPCs**.
At the bottom, RPC protocols provide you with the means to *invoke* remote functions; in order to
do that, they define a *serialization model* as well as indications of success or exceptions. Some
RPC frameworks bind tightly with the programming language (RPyC, Sun RPC, Java RMI, etc.), other
aim at being language-neutral ([Agnos](http://agnos.sf.net), SOAP/WSDL, CORBA, etc.); but when
we drill down to the wire protocol, they all provide the three things I've listed. Of course some
provide more abilities, like a reflection of the exposed service, but we can always reduce such
features to "special functions" exposed by the remote service.

Now I'd like to have a look at the most widely used in the world: HTTP. A request begins with a
method and URL, followed by lots of possible options, and then the payload; the response starts
with a status line, followed by options again, and the payload. I suggest you think of it like
so: the "HTTP service" defines 4-5 functions, namely `GET`, `PUT`, `POST`, `HEAD` and `DELETE`.
These functions take a single mandatory argument (URL) and lots of optional keyword-arguments,
such as














The subject of

Negotiation
Authentication
RPC


 In fact, ever since I began working on
 some six years ago, I had a feeling we're all missing something when
it comes to protocols.

I'd like



Following a conversation with a friend who's into web programming,
In this post I'd like to highlight a topic I've long



[Layer5](https://github.com/tomerfiliba/layer5)
