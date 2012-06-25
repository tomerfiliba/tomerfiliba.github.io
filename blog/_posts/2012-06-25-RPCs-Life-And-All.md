---
layout: blogpost
title: RPCs, Life and All
description: A response to Gavrie Philipson's "Why I Don't Like RPC" post
---

<img src="http://tomerfiliba.com/static/res/2012-06-25-duckface.jpg" class="blog_post_image" />

A colleague of mine, [Gavrie Philipson](https://twitter.com/#!/gavrieph), has written an 
interesting blog post titled [Why I Don't Like RPC](http://philipson.co.il/blog/2012/06/20/why-i-dont-like-rpc/), 
in which he explains that transparent/seamless RPCs (a la [RPyC](http://rpyc.sf.net)) make 
debugging and reasoning efforts hard. For instance, you might work with an object (a proxy) that 
points to an object on the server process, which, in turn, is also a proxy that points to an 
object on yet another server process. Ideally, your local code shouldn't be aware of the 
complexity ("number of hops") or the details -- but that's not always the case.

Well, he won't allow commenting on his blog, so I'm forced to formulate my response here :)
Naturally, I'm biased about this subject, but I thought if I'm on it, why not also cover the 
broader aspects of the issue... However, it just kept getting longer and longer, until I got this 
behemoth of a blog post, so I'm attaching a **TL;DR info box**:

> * Transparent object proxying is only the logical way to extend RPCs to duck-typed languages
> * Asking for a *clear distinction* between local and remote objects ultimately means you're
>   asking for a statically-typed language; it doens't make sense to ask for it in python
> * Network programming is hard, and it's a pity we still work at the socket level; we should 
>   strive for a decent fifth layer that would eliminate all the unnecessary complexity
> * General-purpose RPCs are the **right primitive** over which network programming should be
>   abstracted: it's the missing fifth layer, which every network application reinvents
> * HTTP is a half-baked, broken alternative to a fifth layer; I'm glad ZeroMQ and others are
>   starting to loosen its grasp.
> * RPyC **can** be used efficiently and correctly, it's not an impossible feat. Also, a show 
>   case of how I'm using RPyC to build a testing environment.

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
connection will just "follow you"; the *session* would not be bound to a "physical endpoint". 
These are just some of the issues that layer5 attempted to solve.

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

A general purpose RPC would be *language-agnostic*, support only simple by-value types, such 
as strings, integers and lists (anything more complex can be built on top of that). If would also 
make no assumptions on how remote functions operate, if would only care for their signature. 
You can think of it as a more structured message-passing protocol, where you replace the notion
of "message codes" by "function names". This way, it's easy to see that one can straight-forwardly 
emulate any message-passing protocol or more advanced RPC, over this layer. Heck, it's f***ing 
2012, I want to ``GET("/index.html", Agent="Chrome")``, not formulate ``\r\n``-separated strings or 
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
latency and round-trip time (RTT) are low -- so unless you do something really flawed, you shouldn't 
experience noticeable degradation. Second, the only places that do suffer from RTT are tight-loops,
and to that end, RPyC [already has solutions](http://rpyc.sourceforge.net/api/utils_classic.html#rpyc.utils.helpers.buffiter).
And thirdly, transparency (like any form of abstraction) hides the underlying complexity, which 
means you won't be able to optimize all the way. RPyC makes a choice for simplicity and pythonicity
every time, at the expense of performance.

From my many years of using RPyC, I must say I've never experienced performance **issues** that 
didn't originate from the use of threading and locks in python, or really bad code. And if the times
are tough, you can always apply lightweight optimization techniques, such as locally "caching" 
remote objects that were obtained through a series of lookups, in variables (e.g., 
``myfunc = conn.modules["foo.bar.spam"].myfunc``)... it's normally not that hard. I'm sure Gavrie
has experienced performance issues with RPyC, but I can hardly imagine it could not be solved by
reasonable amounts of refactoring.

Which brings us to the last point Gavrie makes: 

> I don’t like RPC, especially not stateful RPC that supports access of remote objects by reference

I hope we already agreed that a general-purpose RPC is equivalent (if not better than) to any 
"normal" network protocol, so it's really not RPCs that Gavrie hates but stateful/object-proxying
sessions. This invites another, rather philosophic, question: what is *state*? What does it mean 
that a protocol is *stateless*? I'd guess philosophies like [REST](http://en.wikipedia.org/wiki/REST) 
come to mind, but that's just a buzzword. From the broadest Turing-machine perspective, if REST 
or any other protocol were truly stateless, they would have no *effect* on the world and thus would 
be of little significance (they'd be *read-only* protocols). Just to stress this point -- 
``PUT/POST``-ing to a RESTful interface, adding/altering a record in a database table, is clearly 
*stateful*: you changed the state of the DB. 

Therefore, these buzzword-rich protocols boast themselves with the term *stateless*, while they 
mean something very different. In lack of a better term, I'd use **atomicity, durability, 
and reboot-ability** -- which we'll discuss next. And just a last bit of REST: REST has a notion
of idempotency, as GET requests for the same URI should always return the same result (but that's 
not guaranteed). Anyway, the [CRUD model](http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
which REST employs is quite limited and fits only so many real-life problems (many other problems 
can be *reduced* to CRUD, but I don't suppose people would consider this the "right way").

*Atomicity* and *durability* come from the [ACID](http://en.wikipedia.org/wiki/ACID) philosophy of 
databases, and are granted to you freely, assuming you use a DB (who doesn't?). They basically mean 
that a transaction either fully happens (and then its permanently stored), or nothing happens 
(so that no partial results may exist). Reboot-ability is a term I just made up, and it means 
your server might crash and be restarted, or your entire lab might burn away, and the client 
shouldn't be able to detect any difference (other than temporal unavailability, which may be 
compensated for by a cluster). Inherently, it means you don't trust your server to survive over 
long periods of time, and therefore prefer to make it (the server **process**) stateless. 
In effect, it means the server will never make "changes to the world" outside of DB transaction, 
so that a failed transaction could be rolled back, and a new server process could resume where the 
previous one failed. But note the difference: **the server process is stateless, not the protocol**. 

HTTP originally was a connection-less protocol (albeit over TCP), where each request was treated 
separately from the rest and there was hardly any notion of a session. This meant that every 
request had to carry along with it any state information it required. In order to prevent requests 
from growing wildly in size and choking the network, cookies were invented -- which meant the 
server had to store session data, and the cookie was only a key. This already dents the notion
of statelessness, and nowadays, things like websockets break it completely.

RPyC, on the other hand, has a clear notion of a *session*: on each end of the the connection 
there's a dictionary of objects referred to by the other side. This means that should a connection 
drop, there's little chance of restoring the lost session: the dictionaries are lost, and all 
proxies would be invalidated.

But all is not lost: if you only need references to serializable objects, you might as well keep
this dictionary as a DB table. Since the data, including object IDs, would not be lost when the 
server gets restarted, resuming a dropped session is easy. So, if you could live with limited 
functionality, you can be backed by a DB -- but it's not that HTTP offers a better solution.
At least keep your code pythonic and not full of HTTP curses.

Another alternative, which I'll demonstrate in the next section, is making the changes directly
"in the real world": instead of *storing* state, make the changes on long-living entities, and 
then read the info back from them. This way, you're always synchronized, and should you be 
restarted, you'll never use stale data.

## On Testing ##

I'm working now on a testing framework of quite a complicated nature: first, it serves as a 
resource-allocator for hosts and other testing equipment; second, in order to run tests, it must 
create a suitable environment for them. But this is where it gets fun: in order to do set up the 
environment, I must use the utilities that I set out to test... because that's exactly what they 
do. Chicken and egg, anybody?

After a couple of days to toying with it, I settled for the following architecture: 

* Tests are written normally using ``unittest``, but they also make use of a little module (8 LoC 
  or so) that provides them with a means to connect to the resource allocator; this module 
  basically hides the details of setting up an RPyC connection (as the server is well known, etc).
* The resource allocator exposes a simple service, with methods like ``get_system(version = 17)``. 
  It collects the information about the systems from a third-party service and caches it in-memory, 
  so finding a matching system is quick and efficient. Basically, the resource allocator only 
  takes care of distributing systems randomly (we do want to allow for two tests to run on the 
  same system, but wish to avoid unnecessary contention).
* The object returned by ``get_system`` is an instance of a peculiar class called 
  ``HostViewOfSystem``. It basically represents a how the host (running the test) views the system 
  that's been allocated to it, and it has methods like ``get_resource_from_system()`` that look 
  for an unused resource (or create one) and take care of *making it usable by the host*. 

There are quite a few details, but I hope I managed to make the design clear. On the other hand, 
it doesn't seem particularly interesting -- until we get to the last bullet-point -- making the
resource usable by the host. In order to do that, the server (resource allocator) creates a 
temporary directory on the host, onto which it copies (over RPyC) several python packages that
are required for the task. It then fires up a new RPyC server on the host, and sets its 
``PYTHONPATH`` to this temporary location. This RPyC server is based on the fresh-from-the-oven 
``OneShotServer``, which is capable of serving a single client and then quits. The server chooses 
a random port and reports it over stdout, to the resource allocator, who then connects to it.
Then, the ``HostViewOfSystem`` object is given a reference to the newly created RPyC service,
and it uses it to manipulate the host machine in order to set up the environment. Here's a sketch:

    +---Test Host---+            +---ResAlloc Server---+
    |               |            |                     |
    |  -----------  |  .-----------> HostViewOfSystem  |
    |  | Test    |____/          |     |               |
    |  | process |  |            |     |               |
    |  -----------  |     _____________/               |
    |               |    /       |                     |
    |  -----------  |   /        |                     |
    |  | Newly   <-----*         |                     |
    |  | started |  |            |                     |
    |  | RPyC    |  |            +---------------------+ 
    |  | server  |  |
    |  -----------  |
    |               |
    +---------------+

This quite tiresome setup actually takes only ~30 lines of code (and around one second to build), 
and it allows the tested utilities to rely on *stable versions* of themselves. The stable versions
are fetched from the resource allocator server, thus we make absolutely no assumptions on the 
state of the host. Moreover, when we "allocate" a resource for a specific test, we *mark* the 
resource on the system as "in used": it's neither stored in-memory, nor in a DB -- it's marked 
directly on the resource, as metadata. This way, if the resource allocator is restarted, 
no state is lost -- the new instance will read the most up-to-date state from the "real world".
There -- a semi-stateless testing framework based on RPyC... and now I go to bed.

