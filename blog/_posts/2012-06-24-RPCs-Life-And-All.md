---
layout: blogpost
title: RPCs, Life and All
draft: true
description: A response to Gavrie Philipson's "Why I Don't Like RPC" post
side_image: 2012-06-24-duckface.jpg
---

A colleague of mine, [Gavrie Philipson](https://twitter.com/#!/gavrieph), has written an 
interesting [blog post](http://philipson.co.il/blog/2012/06/20/why-i-dont-like-rpc/) titled 
*"Why I Don't Like RPC"*, in which he explains that transparent/seamless RPCs (a la 
[RPyC](http://rpyc.sf.net)) make debugging and reasoning efforts hard. For instance,
you might work with an object (a proxy) that points to an object on the server process,
which, in turn, is also a proxy that points to an object on yet another server process,
and ideally, your local code shouldn't be aware of the complexity ("number of hops") or 
the details.

Well, he won't allow commenting on his blog, so I'm forced to formulate my response here :)
Naturally, I'm biased about this subject, but I thought if I'm on it, why not also cover some 
broader aspects of the issue (at least the ones I find relevant).

## On Transparency ##

Gavrie's main point is that transparency opens the door to (possibly) unplanned and undesired 
complexity. When it's "too easy" to spread around, you might be tempted to (or even unknowingly 
end up with) creating over complicated (and cyclic) dependency graphs, stretching over several 
processes/machines, where it would be quite a feat to see the whole picture. The nice thing is, 
when it works - it just works (and you're happy with your design), but when it fails, you want 
to be able to untangle the mess. As he puts it:

> “Seamless” RPC encourages the writing of spaghetti code, because it’s so easy to mix local 
> and remote code. This makes it deceptively easy to write distributed code without thinking 
> about the design of the API and about which parts should reside on each side of the connection

An ideal remoting solution, according to Gavrie, 

> [...] should make the distinction between local code and remote code crystal 
> clear to the developer.

## On Duck Typing ##

I agree with the key points in Gavrie's argument, and I can assert that *debugging RPyC itself*,
during development, is highly deceptive (hint: never *print* an object...) and calls for 
all sorts of creative solutions. But then again, you *are* using a **duck-typed, interpreted 
language**. The "if it walks like a duck" phrase will soon make a more dramatic entrance, 
but for the time being, suffice it to say we only care for the *runtime behavior* of an object. 
Any object that I can ``.read()`` from or ``.write()`` to, is a "file concept", and thus code 
should be compatible with any object that "adheres to this concept". 

A "file" might be an on-disk file, an in-memory byte stream, a mock object used for testing, 
or a SCSI device located on a remote storage array. **The only natural way to extend the notion
of duck-typing to RPCs is via transparent object proxying**. If ``open()`` doesn't differentiate 
between local and remote (NFS/SMB) files, and if my code doesn't care for anything other than 
*runtime behavior*, such a "file concept" might as well be a proxy object that points to a file 
object on a remote machine. It's only logical... in fact, it's taking duck typing to its 
full potential!

## On Types ##

Gavrie wants the RPC framework to "make the distinction between local code and remote code crystal 
clear to the developer" -- well, Garvie might not have thought about it thoroughly, 
but what he's actually asking for is a **static type system**. Types allow us to *make distinctions 
between objects*; they partition the "universe of data" into disjoint subsets that we can
reason about: integers, floats, strings (to name a few). We can then group several types together, 
under the notion of a *type class*. For instance, floats and integers, albeit inherently different, 
both belong in the type class *number*, which provides us with additional operational semantics 
(like ordering relations, etc.).

We use types to partition the universe, because different "things" have different semantics
and it doesn't make sense to mix them together (modulo converting data of one type to data of
another type). In fact, we normally want to *prevent* ourselves from mixing incompatible objects 
(be it integers and strings, or local and remote references) -- that's why we have type systems, 
and catch type mismatches at compilation time. 

When you require a *clear distinction* between objects, it means you're after a **statically typed 
language**; otherwise, you might as well just come up with a *naming convention*, where all 
variables that (might) refer to a remote object start with ``rem_``. But if you want
this distinction to *propagate* throughout the code, it must be *enforced* by a compiler; 
if you want to keep yourself in the duck-typed world, it doesn't make sense. 

Duck-typing (from a type-theoretic perspective) is like saying there's only a 
[single data type]([http://www.haskell.org/haskellwiki/Why_Haskell_matters), which covers the 
entire universe; all checking is deferred to runtime, in which case it might (1) work, (2) fail, 
(3) silently cause corruption (as in a ``TextToSpeech`` instance, which may as well expose 
a ``.read()`` method, but it surely won't do what we expect the "file concept" to do).

So asking for a "clear distinction" in a duck typed language is simply out of the question. 
What we can ask for is distinction in the level of APIs; for instance, 
``write_local_file(filename)`` vs. ``write_remote_file(filename)``, but that breaks the 
"spirit of duck-typing", where objects are no longer considered equal (even though they provide
the desired runtime behavior). It's like pointing out the ugly ducklings and making fun of them...
that's not cool.

Just to contrast, an RPyC-like library for Haskell would expose remote references as a distinct
type class. You could have a function like ``remoteSum :: (Num a) => Remote [a] -> a``, which 
takes a reference to a remote list of ``a``'s, and returns its sum. Because it *knows* it 
operates on remote lists, it might be able to "move" the actual summation remotely, instead of
sending the entire list over the network, item by item. I think this qualifies for a 
"crystal clear distinction", but of course, that's not what the snake teaches.

## On Networks ##

It seems to me that people find it easy to abstract all sorts of concepts, as long as they don't 
concern networks. When there's network involved, they tend to want to "get a feel of the wire"...
so they might use HTTP instead of the NIC directly, but they won't take the next step and treat 
network resources as first class objects. There's always a gap, between what's *here* and what's 
*there*, and we're still too aware of the *how to get there* details... a gap that should have 
been bridged over long ago.

As I see it, it stems from two primal fears, so to speak: networks are *hard* (timeouts, routing, 
DNS, reconnects, authentication, compression, tunneling, round-trip time, ...) and *unreliable*. 
As far as unreliability goes, there's not much you *can* do about it; after all, the server is 
a process like any other, and may crash at any point of time. If that's not enough, the remote 
machine might freeze or reboot. But then again, your local machine might kernel-panic or just 
go down with a power failure, losing any unflushed data... but that's life. On the other hand,
it seems to me that overall (hardware?) unreliability rates are going down with time, which is 
a promising outlook.

The "hardness" of network programming, on the other hand, is something we *can solve*. Good network 
programming is hard, there's no question there, but for some reason, instead of solving the 
problem once of for all in a generic manner, it seems that every protocol/network-oriented 
application seeks to start at square one. Of course, done this way, it only handles the aspects 
it finds relevant... doing network programming at the socket level is analogous to rewriting
the kernel for every desktop application. It doesn't make sense.

I've started (and abandoned) an ambitious project called [layer5](http://tomerfiliba.com/projects), 
which aimed to concentrate all the network-related sorcery in a single place, so that programs on
top of it wouldn't have to care. It originated from my frustration with network programming in 
general (and in RPyC in particular)... things like handling timeouts, reconnects, authentication, 
negotiation, compression, serialization, load distribution, caching, error reporting -- you name it.

Just to show-off a couple of ideas, consider a socket connection being dropped for some reason: 
if the network layer knew how to reconnect and resume the session, or automatically resend a 
request after some timeout (all configurable, of course), there would be no need for the 
application to be aware of anything. And, once you "lift" your code up from the socket layer,
you can enable things like "moving targets", where you may switch an IP address (wifi/3G) and the 
connection will just "follow you"; the *session* would not be bound to an endpoint. These are 
just some of the issues layer5 attempted to solve.

## On RPCs ##

Let me make a bold claim: **everything is RPC**. So, by *everything* I mean *virtually all* 
connection-oriented network protocols (e.g., excluding broadcasts/multicasts/streaming), 
and I take *RPC* to its broadest sense: an RPC is any message-oriented protocol in which one side 
makes requests that the other side fulfills: basically invoking a remote function. Naturally, 
in order to convey a message, the RPC imposes a serialization format, and in order to tell success
from failure, it must also define "return codes". **Note:** I've been planning to write about this
topic for a very long time, but never got to it; it surely deserves a post of its own, but 
until that happens, please consider this a "briefing".

As a case study, let's examine HTTP: there are 4 (or so) *methods*: ``GET``, ``PUT``, ``POST``
and ``DELETE``. Each such *method* takes *arguments*, like the URL, cookies, accept-encoding,
etc. Some of them are required, some are optional; some pertain to the transport layer 
(content-length, compression, timeouts) while others to the method itself (URL, cookie, ...).
It also defines *status codes* for distinguishing errors from success (and again, it mixes 
transport-layer errors like *redirect* with method-level ones like *not found* or
*internal server error*). It also defines a (very loose) serialization format for encoding
the method's arguments (newline-separated key-value strings) and the payload 
(``multipart/form-data``)... So, from an RPC point of view, HTTP is a service that provides 4 
functions (*methods*), whose signature is something like ``(url, formdata = None, **kwargs)``.

Another example is ``tenlet`` -- it basically provides a function whose signature
is ``void write(char ch)``; when you type, ``write`` is invoked for each key stroke. Aside from
sending characters, telnet also provides all sorts of *negotiation* options or *commands*, like 
``bool set_binary()``, ``void set_terminal(string)``, etc.

As with most **ad-hoc RPC** protocols, the two we've examined make horrible design choices like 
mixing transport-layer options with "business logic" (HTTP) or sending control in-band with the 
data (telnet), where a mere ``\xFF`` character in the stream marks the beginning of a command, 
so anyone can (maliciously or accidentally) inject commands into the stream. Yet another pitfall 
of these protocols is, they begin small, targeting a specific task, but if they're successful,
they grow to [incorporate](http://www.telnet.org/htm/dev.htm) many unrelated things, like 
encryption and proxy support... as if security is something you sprinkle on top.

The main point I'm trying to make here is this: **virtually all protocols are basically 
degenerate forms of RPC**. To paraphrase [Greenspun](http://en.wikipedia.org/wiki/Greenspun's_tenth_rule),
all sufficiently complicated network protocols end up redoing compression, security, authentication,
framing, serialization, negotiation/versioning, discovery, you name it (*Filiba's Eleventh Rule*). 
This observation has brought me to the conclusion that doing network programming at the 
"byte level" is wrong, and that a **general-purpose RPC layer** is the **right primitive** for this.

A general purpose RPC would be language-agnostic, support only by-value types, such as strings,
integers and lists (anything more complex can be built on top of that). If would also make no 
assumptions on how remote functions operate, if would only care for their signature. You can think
of it as a more structured message-passing protocol, but one that can straight-forwardly emulate 
any message-passing protocol, RPC, etc. It's f***ing 2012, I want to 
``GET("/index.html", Agent="Chrome")``, not formulate ``\r\n``-separated strings or 
care about XML/JSON.

Layer5 (mentioned in the previous section) was to expose such a generic RPC, upon which 
applications would base their protocols. You could always just implement a 
``bytes send(bytes data)`` RPC (over which would continue to pass your byte-level messages),
or implement a more semantic interface -- your choice. Either way, you'd benefit from layer5's
handling of reconnects, authentication, and the rest of the list.

## On HTTP ##

Truth is, we sort-of already have such a "general purpose" layer 5 protocol, called HTTP. By a 
strange twist of fate, HTTP has become the de-facto application layer of choice, over which all 
kinds of protocols now operate. And we've managed to hide the gruesome details of HTTP under 
programmer-friendly libraries and APIs, so we are in a "better shape" now. Yet HTTP is such a 
**miserable choice** for this purpose (hence abominations like 
[Websockets](http://en.wikipedia.org/wiki/WebSocket) arose), and we all pay the price 
(programmatically-speaking, but also in the sense of network bandwidth, CPU time and electricity 
bills).

In my opinion, HTTP owes its success to another misfortunate happening - *firewalls*. In the days 
of yore, people thought they could eliminate threats simply by blocking all TCP ports, except
for safe/trusted ones. HTTP was considered safe, as it only transfered "hypertext", so all 
firewalls allowed port 80 traffic by default. This fact has led to many protocols being designed 
to work on top of HTTP, to be firewall-friendly... which meant firewalls no longer served the 
purpose for which they were conceived: blocking ports was not enough, so firewalls had to become 
*content-aware* anyway. Long story short -- we've only managed to push the problem one level up:
instead of solving it in the forth layer, we now do it in the application layer... no matter what
the port number is.

However, this initial edge that HTTP had, helped in making it the de-facto transport layer of 
choice, which of course had a snowball effect. I'm only happy to see competing protocols like 
[ZeroMQ](http://www.zeromq.org/) and [AMQP](http://en.wikipedia.org/wiki/Advanced_Message_Queuing_Protocol)
are starting to take some market share. Down with HTTP!

## On RPyC ##

Coming back to Gavrie's post, he brings up two additional points. The first: 

> In addition, its performance can quickly deteriorate: Objects are being serialized back and 
> forth all the time, and tens of implicit network round-trips introduce latency all around the code.

Performance is a tricky thing. First, RPyC is mostly ever used on local, secure networks, where 
latency and round-trip time are low (so unless you build a self-resonanting dependency graph, 
there shouldn't be any problem). Second, the only places that do suffer from RTT are tight-loops,
and to that end, RPyC [has solutions](http://rpyc.sourceforge.net/api/utils_classic.html#rpyc.utils.helpers.buffiter).
Thirdly, transparency and abstraction layer simplify your life, but they always hide incurred 
complexity. That's the price your have to pay for being ignorant of the network behind.

From my many years of using RPyC, I've never experienced performance issues that didn't originate
from (a) the use of threading and locks in python (b) really bad code. And you can always apply
lightweight caching techniques, such as ``myfunc = conn.modules["foo.bar.spam"].myfunc``, to save 
lookups.

Which brings us to the last point Gavrie makes: 

> I don’t like RPC, especially not stateful RPC that supports access of remote objects by reference

I hope we already agreed that a general-purpose RPC equivalent (if not better than) to any 
reasonable network protocol, so it's really not RPCs that Gavrie hates but stateful/object-proxying
ones. This invites another, rather philosophic, question: what is *state*? What does it mean that
a protocol is *stateless*? I'd guess philosophies like [REST](http://en.wikipedia.org/wiki/REST) 
come to mind, but the question still remains. From the broadest Turing-machine perspective, if 
REST or any other protocol were truly stateless, they would have no *effect* on the world and 
they would of little significance (you could call them *read-only* protocols). Just to make it 
clear -- ``POST``-ing to a REST interface to add a record to some database table is clearly 
*stateful*: a new row has been created (previously, queries on its key would fail, while now 
they'd succeed). 

Therefore, all of these just boast themselves with the term *stateless*, while they mean something 
very different. In lack of a better term, I'd use **atomicity, durability, and reboot-ability** --
which we'll discuss in a moment. Just a note on REST: in REST, there's also a sort of idempotency, 
as GET requests should always return the same result for the same URI (but even that's no 
guaranteed). Anyway, the [CRUD model](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
which REST employs is quite limited and fits only so many real-life problems (many other problems 
can be *reduced* to CRUD, but I don't suppose people consider that the "right way").

Atomicity and durability come from the [ACID](http://en.wikipedia.org/wiki/ACID) philosophy of 
databases, and are granted to you freely, assuming you use a DB (who doesn't?). They basically mean 
that a transaction either fully happens (and then its safely/permanently stored), or nothing happens 
(no partial results are allowed). Reboot-ability is a term I just made up, and it means your server 
might crash and be restarted, and the client shouldn't be able to detect any difference (other 
than unavailability, which may be compensated for by a cluster). Inherently, it means you don't 
trust your server to survive over long periods of time, and therefore prefer to make it (the 
server **process**) stateless. In effect, it means the server will never make changes to the 
"world" outside of DB transaction, so that a failed transaction could be rolled back, and a new
server process could resume from where the previous one failed. But note the difference: the 
server process is stateless, not the protocol. 

HTTP originally was a connection-less protocol (albeit over TCP), where each request was treated 
separately from the rest and there's hardly any notion of a session. This means that every request 
should carry with it any stateful information it requires. Normally, in order to prevent requests 
from growing wildly, cookies are used -- which means the server has to store a lot of data, into 
which the cookie serves as a key. With time, HTTP 1.1 added more state, and nowadays, websockets 
break the concept completely.

RPyC, on the other hand, has a clear notion of a session: the connection holds a dictionary on 
each end, which holds "referred objects", which are accessible to the other party according to
their ID. This means that if a connection is dropped, there's little chance of restoring the
lost session: the dictionaries were cleared, and object IDs may turn out different next time. 
But all is not lost: if you only need references to serializable objects, you might as well keep
the referred objects dictionary in a DB table. Since the data, including object IDs, would not 
be lost when the server gets restarted, resuming a dropped session is easy. So we're limiting the 
RPyC's functionality, but if you're backed by a DB, you have to use only serializable objects
anyway... let's at least keep them pythonic.

Another alternative, which I'll demonstrate in the next section, is making the changes directly
"in the world": instead of storing state, make the changes on long-living objects, and then read 
it back from them.

## On Testing ##

TAAS from a bird's eye view





