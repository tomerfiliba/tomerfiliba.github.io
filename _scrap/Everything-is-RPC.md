---
layout: post
title: Everything is RPC
---

Finally! It's been about three years since I had this revelation and wanted to formulate it into a 
nice article... but I guess I'd have to settle for a blog post. So consider this the first 
installment of an article titled *All Protocols are but Degenerate RPCs*. Okay, this bold 
claim requires some defending, so let's start with some background.

I assume you know what an application-level 
[protocol](http://en.wikipedia.org/wiki/Communications_protocol] is, as well as 
[RPC](http://en.wikipedia.org/wiki/Remote_procedure_call) (or more generally 
[IPC](http://en.wikipedia.org/wiki/Inter-process_communication)).

## What's a Protocol ##

Transport-layer-level and streaming protocols aside, all communication protocols share some 
common traits: they define a *data serialization model*, a set of *commands* that take *parameters*
(which the client invokes), and a way of distinguishing successful from erroneous results. 
Some go further and define quality-of-service and transport parameters such as (timeout, 
compression, etc.), or sessions (cookies, authentication, etc.).

The obvious candidate to demonstrate my thesis on is HTTP: the commands (or *functions*) 
are `GET`, `POST`, `HEAD`, `PUT` and `DELETE`, their parameters are the URL and the header 
options (like `varargs`), and return codes are used to distinguish success (`200`) from failure 
(`4xx`, `5xx`). It takes care of compression, timeouts, keep-alives, encoding, authentication 
and session management; and it defines a data serialization model (both for headers and for 
payload -- MIME types), albeit too permissive and textual. Surprisingly (or not), HTTP became 
sort of a multipurpose protocol that has little to do with its original intent. Except for 
fetching web pages, it mostly serves today as the "standard" *transport layer* over which more 
sophisticated protocols (ICQ, SOAP, XMLRPC, REST, XMPP, and the list goes on) talk. 
On the other hand -- HTTP is doing it all wrong, as we'll see in a minute.

## Some Examples ##

In the mean time, I wish to analyze some well-known protocols, to show how they map to my RPC model. 
I won't go into too many details, because showing a full isomorphism between STMP and RPC is basically 
implementing one. 

Let's start with a very simple protocol: [telnet](http://en.wikipedia.org/wiki/Telnet). A telnet 
connection begins by negotiating options (capabilities) between the local terminal and the host 
(like newlines, 7-bit or 8-bit characters, etc.), and then it functions as a "dumb" transport 
layer that simply moves bytes from here to there. "Dumb" is in quotations, because it's a little 
bit more complicated than this, you see, there's an escape character (`\xFF`) after which 
special commands can be sent to the telnet server itself. In fact, the negotiation phase is 
basically a series of ``\xFF`` commands that set these options. So basically, if we think of 
an analogy to RPCs, telnet defines two functions: `void send_data(string data)` and 
`int send_command(string data)`. We can fully implement a telnet server and client with this 
abstraction. Now again, we can "refactor" this API, so instead of sending commands as raw strings, 
we can map them to functions of their own, i.e., `bool negotiate_newline(char the_newline_char)` 
or `bool negotiate_8bit()`. These function calls would


## Corollary ##

The obvious conclusion from this claim is, of course, all protocols could be replaced by a single, 
more capable RPC protocol.

