---
layout: blogpost
title: RPCs, Life and All
published: false
description: 
    A response to Gavrie Philipson's "Why I Don't Like RPC" post
side_image: http://tomerfiliba.com/static/res/2012-06-21-duckface.jpg
---

A colleague of mine, [Gavrie Philipson](https://twitter.com/#!/gavrieph), has written an 
interesting [blog post](http://philipson.co.il/blog/2012/06/20/why-i-dont-like-rpc/) titled 
"Why I Don't Like RPC", in which he explains that transparent/seamless RPCs (a la 
[RPyC](http://rpyc.sf.net)) make debugging and reasoning efforts hard. For instance,
you might work with an object (a proxy) that points to an object on the server process,
which, in turn, is also a proxy that points to an object on yet another server process.
When all goes well, your local code shouldn't be aware of the complexity or the details.

Well, his blog doesn't support commenting, so I'm forced to formulate my response here :)
I'm biased of course, but I thought if I'm on it, I'd also cover some broader aspects of the issue
(or at least *I* find them related).

## On Transparency ##

Gavrie's main point is that transparency opens the door to (possibly) unplanned, undesired 
complexity. When it's "too easy" to spread around, you might be tempted to (or even unknowingly 
end up with) create complicated (and cyclic) dependency graphs, stretching over several processes,
where it would be quite a feat to get the whole picture. As I said before, when it works - 
it just works (and you're happy with your design), but when it fails, you want to be able to 
untangle the mess. As he puts it:

> “Seamless” RPC encourages the writing of spaghetti code, because it’s so easy to mix local 
> and remote code. This makes it deceptively easy to write distributed code without thinking 
> about the design of the API and about which parts should reside on each side of the connection

An ideal remoting solution, according to Gavrie, 

> [...] should make the distinction between local code and remote code crystal 
> clear to the developer.

## On Duck Typing ##

I agree with the key points in Gavrie's argument, and I can assert that *debugging RPyC itself*,
during development, is highly deceptive (hint: never *print* an object...) and calls for 
all sorts of creative solutions. But then again, you're using a **duck-typed, interpreted language**.
The "if it walks like a duck" phrase will soon make a more dramatic entrance, but for the time 
being, suffice it to say we only care for the *runtime behavior* of an object. Any object that
I can ``.read()`` from or ``.write()`` to, is a "file concept", and thus code should be compatible 
with any object that "adheres to this concept". 

This "file" might be an on-disk file, an in-memory byte stream, a mock object used for testing, 
or a SCSI device located on a remote storage array. **The only natural way to extend the idea 
of duck-typing to RPCs is via transparent RPCs**. If ``open()`` doesn't differentiate between 
local and remote (NFS/SMB) files, and if my code doesn't care for anything other than *runtime 
behavior*, such a "file concept" might as well be a proxy object that points to a file object on a 
remote machine. It's only logical... in fact, it's the highest form of duck typing!

## On Types ##

Gavrie wants the framework to "make the distinction between local code and remote code crystal 
clear to the developer" -- well, Garvie might not have thought about it thoroughly, 
but he actually **asking for a static type system**. Types allow you to make distinctions 
between objects; they partition the "world of data" into disjoint subsets that we can reason about:
integers, floats, strings (to name a few). We can then group several types together, under a 
notion of a *type class*. For instance, floats and integers both belong in the type class *number*,
which provides us with additional operational semantics (like ordering, etc.).

We use types to partition the universe, because different "things" have different semantics
and it doesn't make sense to mix them together. In fact, we want to prevent ourselves from doing
so -- that's why we have type systems that catch mismatches at compilation time. Of course we 
might *convert* (not *cast*!) one kind of data to another, but the two resulting data would 
belong to distinct types.

If you want a *clear distinction* between objects, it means you want a **statically typed 
language**; otherwise, just come up with a naming convention where all variables that
(might) refer to a remote object, should start with an identifiable prefix. If you want 
this distinction to *propagate* throughout the code, it must be enforced by a compiler. On the
other hand, if you want to keep yourself in the duck-typed world, it doesn't make sense. 

Duck-typing (from a type-theoretic perspective) is like saying there's only a 
[single data type]([http://www.haskell.org/haskellwiki/Why_Haskell_matters), which covers the 
entire universe; all checking is deferred to runtime, in which case it might (1) work, (2) fail, 
(3) silently cause corruption (as in a ``TextToSpeech`` instance, which may as well expose 
a ``.read()`` method, but it surely won't do what we expect the "file concept" to do).

So asking for a "clear distinction" in a duck typed language is simply out of the question. 
What you can ask for is distinction in the level of APIs; for instance, 
``write_local_file(filename)`` vs. ``write_remote_file(filename)``, but that breaks the 
"spirit of duck-typing", where objects are no longer considered equal, although they provide
the correct runtime behavior. You point out the ugly ducklings and laugh at them; that's not cool.

Just to contrast, an RPyC-like library for Haskell would expose remote references as a distinct
type class. You could have a function like ``remoteSum :: (Num a) => Remote [a] -> a``, which 
takes a reference to a remote list of ``a``'s, and returns its sum. Because it *knows* it 
operates on remote lists, it might be able to "move" the actual summation remotely, instead of
sending the entire list over the network, item by item. I think this qualifies for a 
"crystal clear distinction", but of course, that's not what Python teaches.

## On Networks ##

It seems to me that people find it easy to abstract all sorts of concepts, as long as they don't 
concern networks. When there's network involved, they tend to want to "get a feel of the wire"...
so they might use HTTP and the NIC directly, but they won't take the next step and treat 
network resources as first class objects... there's always a gap.

I think this stems from two primal fears: networks are hard (timeouts, routing, DNS, reconnects,
authentication, compression, round-trip time, ...) and unreliable. As far as unreliability goes, 
there's not much you *can* do; after all, the server is a process like any other, and may crash 
at any point of time. If that's not enough, the remote machine might freeze or reboot. But then 
again, your local machine might kernel-panic, or just drop dead by a power failure. 
All unflushed data would be lost, and atomic transaction might be corrupted... but that's life 
with a Turing Machine!

The "hardness" of network programming, on the other hand, is something we *can solve*. I've started 
(and abandoned) an ambitious project called [layer5](http://tomerfiliba.com/projects), which
aimed to concentrate all the network-related sorcery in a single place, so that libraries on
top of it wouldn't have to care. I never wrote a mission statement, and I'm surely not going to
write one now, so [this](https://github.com/tomerfiliba/layer5/blob/master/negotiators/v1.txt)
is as close as it gets to explaining the idea. It originated from my frustration with network 
programming in general (and in RPyC in particular)... handling timeouts, reconnects, authentication, 
negotiation, compression, serialization, buffer-overflows, DoS, caching, reporting errors -- it 
ought to be handled once and all!

I must admit [zeroMQ](http://www.zeromq.org/) is approaching what I had in mind.

## On RPCs ##

Let me make a bold claim: **everything is RPC**. So, by *everything* I mean *virtually all* 
connection-oriented network protocols (e.g., not including broadcasts/multicasts/streaming), 
and I take *RPC* to its broadest sense: an RPC is any message-oriented protocol in which one side 
makes requests that the other side fulfills: you basically invoke a remote function. Naturally, 
in order to convey a message, the RPC imposes a serialization format, and in order to tell success
from failure, it must also define "return codes". **Note:** it's something I've been planning to 
discuss for a long time, but never got to it... this surely deserves a post of its own, but 
until that happens, you'll have to settle for this shorter version.

As a case study, let's examine HTTP: there are 4 (or so) *methods*: ``GET``, ``PUT``, ``POST``
and ``DELETE``. Each such *method* takes *arguments*, like the URL, cookies, accept-encoding,
etc. Some of them are required, some are optional; some pertain to the transport layer 
(content-length, compression, timeouts) while others to the method itself (URL, cookie, ...).
It also defines *status codes* for distinguishing errors from success (and again, it mixes 
transport-layer errors like *redirect* or *moved* with method-level ones like *not found* or
*internal server error*). It also defines a (very loose) serialization format for encoding
the method's arguments (newline-separated key-value strings) and the payload 
(``multipart/form-data``)... So, from an RPC point of view, HTTP is a service that provides 4 
functions (*methods*), whose signature is something like ``(url, formdata = None, **kwargs)``.

Another example is ``tenlet`` -- it basically provides a function whose signature
is ``void write(char ch)``; when you type, ``write`` is invoked for each key stroke. Aside from
sending characters, telnet also provides all sorts of *negotiation* options or *commands*, like 
``bool set_binary()``, ``void set_term(string)``, etc.

As with most **ad-hoc RPC** protocols, the two we've examined make horrible design choices like 
mixing transport-layer options with "business logic" (HTTP) or send control in-band with the 
data (telnet), where a mere ``\xFF`` character in the stream marks the beginning of a command, 
so anyone can (maliciously or accidentally) inject commands. Yet another pitfall of these protocols
is, they begin small, targeting a specific task, but they grow to 
[incorporate](http://www.telnet.org/htm/dev.htm) many unrelated things, like encryption and proxy 
support... as if security is something you sprinkle on top.

The main point I'm trying to make here is this: **virtually all protocols are basically 
degenerate forms of RPC**. To paraphrase [Greenspun](http://en.wikipedia.org/wiki/Greenspun's_tenth_rule),
all sufficiently complicated network protocols end up redoing compression, security, authentication,
framing, serialization, negotiation, etc. (*Filiba's Eleventh Rule*). This observation has brought 
me to the conclusion that doing network programming at the "byte level" is wrong, and that a 
**general-purpose RPC layer** is the **right primitive** for this. It would allow us to decouple
the network from the programming... I want to ``GET("google.com/index.html", Agent="Chrome")``,
not formulate ``\r\n``-separated strings or care about XML/JSON; I want to send the number ``5``,
without being troubled with endianity, or send strings without being troubled with escaping. It's
2012, for crying out loud.

## On HTTP ##

Truth is, we've managed to hide the gruesome HTTP details from the programmer; but that's just for 
HTTP. And by a strange twist of fate, HTTP has become the de-facto fifth layer, over which all 
sorts of protocols now operate... yet HTTP is such a **miserable choice** for this (hence 
abominations like [Websockets](http://en.wikipedia.org/wiki/WebSocket) arose), and we all pay 
the price (programmatically, but also in network bandwidth and CPU time).

In my opinion, HTTP owes its success to another misfortunate thing - *firewalls*. In the days of
yore, people thought they could eliminate threats by simply blocking all TCP ports, except
for safe/trusted ones. HTTP was considered safe, as it only "transfers hypertext", so all 
firewalls allowed port 80 traffic by default. This, in turn, has led to many protocols being 
designed to work on top of HTTP, to be firewall-friendlt... which meant firewalls no longer served 
the purpose for which they were conceived. Blocking ports was not enough, so firewalls had 
to become *content-aware*. Long story short -- we've only managed to push the problem one level up:
instead of solving it in the forth layer, we now do it in the application layer.

However, this initial edge that HTTP had, helped in making it the de-facto transport layer of 
choice, which of course had a snowball effect. I'm only happy to see competing protocols like 
ZeroMQ and AMQP are starting to take some market share. Down with HTTP!

## On RPyC ##

In his post, Gavrie brings up two additional points: 

> In addition, its performance can quickly deteriorate: Objects are being serialized back and 
> forth all the time, and tens of implicit network round-trips introduce latency all around the code.

and 

> I don’t like RPC, especially not stateful RPC that supports access of remote objects by reference

Performance

This refers to REST

* "stateless" message passing
* roundtrips in real life, tight loops
* transparency: hiding complexity, performance


## On Testing ##

TAAS from a bird's eye view





