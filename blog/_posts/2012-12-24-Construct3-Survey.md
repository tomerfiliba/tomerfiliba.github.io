---
layout: blogpost
title: "Survey of Construct 3"
tags: []
description: "Discussing the plans for Construct 3"
draft: true
---

<img src="http://tomerfiliba.com/static/res/2012-05-16-construct-logo-small.png" title="Construct" class="blog-post-image" />

I'm working on [Construct3](http://tomerfiliba.com/blog/Construct-Plans) again and I'm exploring lots of new ideas.
I wanted to share these ideas and get feedback on them from users, so I won't end up with a mess. It starts slow
and with fancy words, but it dives into code right away.

Note: because Construct 3 is incompatible with Construct 2, the name of the package has changed to ``construct3``.

## Introduction ##
Construct is a **binary packing combinators** library for Python, with which you can define rich **data structures**.
Unlike most alternatives, these data structures can be used for **both packing and unpacking** of binary data; for 
instance, once you define *what* a TCP packet is, you can analyze packets or construct ones on your own, with no 
additional code.

### See also ###

* [Construct 2](http://pypi.python.org/pypi/construct) 

* [Pickler combinators](http://research.microsoft.com/en-us/um/people/akenn/fun/picklercombinators.pdf)

## Basics ##
Packers are objects that expose the two methods ``pack(obj)`` and ``unpack(data)``. Intuitively, ``pack`` takes an
object suitable with that packer, and returns a binary representation of it; ``unpack`` is the inverse operation,
which takes a binary representation and returns a Python object. Here's the most basic example:

{% highlight pycon %}
>>> from construct3 import byte
>>>
>>> byte.pack(127)
'\x7f'
>>> byte.unpack('\x7f')
127
{% endhighlight %}

There's more than mere ``byte``, of course: the numeric family consists of ``int(8|16|24|32|64)(s|u)(b|l)`` 
(e.g., ``int32ul``) and ``float(32|64)(b|l)``, where ``s`` = signed, ``u`` = unsigned, ``b`` = big endian and 
``l`` = little endian, but we will overlook those for now. By the way, ``byte`` is an alias for ``int8u``.

But Construct is a library of *combinators*, i.e., it gains it's power by *combining* simple elements into more 
complex one. The simplest combinator is ``Sequence``, which creates a new packer from smaller ones. In this example,
we're going to define an IP address, which comprises of 4 bytes:

{% highlight pycon %}
>>> from construct3 import Sequence
>>> ipaddr = Sequence(byte, byte, byte, byte)
>>> ipaddr
Sequence(int8u, int8u, int8u, int8u)
>>> ipaddr.unpack('\x7f\x00\x00\x01')
[127, 0, 0, 1]
>>> ipaddr.pack([192, 168, 2, 1])
'\xc0\xa8\x02\x01'
{% endhighlight %}

Naturally, we can created nested sequences (not that it makes sense right now, but it's important to note):

{% highlight pycon %}
>>> Sequence(Sequence(byte, byte), byte, byte).unpack("ABCD")
[[65, 66], 67, 68]
{% endhighlight %}

As combining packers is our bread-and-butter here, why not make it shorter? We can use the *bind* operator,
``>>``, to concatenate packers and form sequences. Here's how it looks:

{% highlight pycon %}
>>> ipaddr = byte >> byte >> byte >> byte
>>> ipaddr
Sequence(int8u, int8u, int8u, int8u)
{% endhighlight %}

Sequences can be heterogeneous (consist of several kinds of packers), e.g., ``Sequence(byte, int16ul)``. However, 
if the data we're dealing with is homogeneous, we can use ``Arrays`` instead. For instance, we can define ``ipaddr``
as an array of 4 bytes:

{% highlight pycon %}
>>> from construct3 import Array
>>> ipaddr = Array(4, byte)
>>> ipaddr
Range(4, 4, int8u)
>>> ipaddr.unpack("\x7f\x00\x00\x01")
[127, 0, 0, 1]
{% endhighlight %}

Note that ``Array`` is actually a shorthand for ``Range``. We'll cover that later on.

But as arrays themselves are a pretty common feature, let's simplify their construction: You can create arrays using 
the subscript (``[]``) notation:

{% highlight pycon %}
>>> ipaddr = byte[4]
>>> ipaddr
Range(4, 4, int8u)
{% endhighlight %}

Isn't it cool?

## More Elaborate Structures ##
So far we've only worked with data in the form of lists. However, many times we would like to give names to 
the subcomponents that make up our data structure: enter ``Struct``. Named after the C ``struct`` statement, 
``Struct`` takes pairs of ``(name, packer)`` and returns a composite packer.

{% highlight pycon %}
>>> from construct3 import Struct
>>>
>>> ipaddr = Struct(('a', byte), ('b', byte), ('c', byte), ('d', byte))
>>> x = ipaddr.unpack('\xc0\xa8\x02\x01')
>>> x
Container:
  a = 192
  b = 168
  c = 2
  d = 1
>>> x.a
192
>>> x["a"]
192
{% endhighlight %}

Notice that unpacking a ``Struct`` breaks down the data into a ``Container`` object, which is simply a 
convenience-wrapper around good old ``dict``. Likewise, given a dict-like object, you can pack it back into bytes: 

{% highlight pycon %}
>>> ipaddr.pack({"a" : 192, "b" : 168, "c" : 2, "d" : 1})
'\xc0\xa8\x02\x01'
{% endhighlight %}

Structures can soon grow large and have many nested structures within them. Using pairs of ``("name", packer)`` quickly
becomes a burden as the you're surrounded by parenthesis:

{% highlight python %}
Struct(
    ("foo", byte),
    ("bar", Struct(
        ("spam", int16ul),
        ("bacon", int64sb),
    )),
    ("viking", int32sl),
)
{% endhighlight %}

For this reason there's yet another syntactic sugar: the *slash* (``/``) operator. This operator is used as 
``"name" / packer``, and simply returns ``("name", packer)``. The code snippet above now becomes easier to read:

{% highlight python %}
Struct(
    "foo" / byte,
    "bar" / Struct(
        ("spam", int16ul),
        ("bacon", int64sb),
    ),
    "viking" / int32sl,
)
{% endhighlight %}

And going back to our ``ipaddr`` example,

{% highlight pycon %}
>>> ipaddr = Struct(
...     'a' / byte, 
...     'b' / byte, 
...     'c' / byte, 
...     'd' / byte,
... )
...
>>> ipaddr
Struct(('a', int8u), ('b', int8u), ('c', int8u), ('d', int8u))
{% endhighlight %}

Remember the *bind* operator (``>>``)? It can be used just the same here, creating one-liner Structs quick and
easy:

{% highlight pycon %}
>>> ipaddr = 'a' / byte >> 'b' / byte >> 'c' / byte >> 'd' / byte
>>> ipaddr
Struct(('a', int8u), ('b', int8u), ('c', int8u), ('d', int8u))
{% endhighlight %}

### Note ###
The "inline style" is appropriate for small Structs and Sequences (2-4 members). When dealing with
larger structures, use the "multiline" version instead. Also note that these are all but syntactic sugars: If you 
don't like their looks, you can always use the expanded form.

## Bits: When Bytes are not Small Enough ##

Bytes are easy to work with, but protocols and file formats often talk in different levels of granularity,
switching between bits and bytes (octets). For instance, here's the SCSI CDB of ``READ6``:

<a href="http://en.wikipedia.org/wiki/SCSI_Read_Commands">
<img src="http://tomerfiliba.com/static/res/2012-12-24-read6.png" title="SCSI READ6" />
</a>

The LUN component is 3 bits long and the ``LBA`` component is 21 bits long... what are we to do? Before we can
answer this question, it's time to talk a little about how Construct works under the hood - specifically, how
Construct represents data. In short, Construct operates on a stream of *units*, which normally happen to be bytes. 
When needed, this stream can be replaced to provide different units, say bits. Here's an example:

{% highlight python %}
read6 = Struct(
    "opcode" / byte,
    "address" / Bitwise(Struct(
        "lun" / Bits(3),
        "lba" / Bits(21),
    )),
    "transfer_length" / byte,
    "control" / byte,
)
{% endhighlight %}

Note how we switch between bytes and bits: *opcode* is a byte, followed by *address* which operates on bits. The
``Bitwise`` packer replaces the underlying byte-stream with a bit-stream, so the contained Struct operates on bits.
The ``Bits`` packer reads that many bits from the stream and converts them to an integer; for convenience, there
are also ``bit`` (a single bit), ``nibble`` (four bits) and ``octet`` (eight bits).

In theory, Construct could be operate on various other units, but practice shows byte streams and bit streams are 
the most useful ones. Some exceptions are the processing of compressed or encoded data, but these are beyond the
scope of this discussion.

## Powering Up: Adapters ##

So far we've looked at data in its raw form (e.g., ``[127, 0, 0, 1]``), but it is normally desirable to transform 
data into easier to work with representations. For instance, we may prefer ``127.0.0.1`` to a list of numbers, and
for that reason, we have **adapters**. The distinction between adapters and packers is actually quite clear:
packers work at the *stream level* while adapters work at the *object level*; this lets you add power without 
interfering with the low-level machinery.

{% highlight python %}
class IpAdapter(Adapter):
    def decode(self, arr, ctx):                  # called by unpack()
        return  ".".join(map(str, arr))
    def encode(self, ipstr, ctx):                # called by pack()
        return map(int, ipstr.split("."))
{% endhighlight %}

{% highlight pycon %}
>>> ipaddr = IpAdapter(byte[4])
>>> ipaddr.unpack('\xc0\xa8\x02\x01')
'192.168.2.1'
>>> ipaddr.pack('127.0.0.1')
'\x7f\x00\x00\x01'
{% endhighlight %}

When we only have a single use for an adapter (and it's simple enough), we can even go one-liner here:

{% highlight pycon %}
ipaddr = IpAdapter(byte[4], 
    decode = lambda arr, ctx: ".".join(map(str, arr)),
    encode = lambda ipstr, ctx: map(int, ipstr.split("."))
)
{% endhighlight %}

At this point, adapters might seem quite trivial, but they can do much more than this. For instance, the integer
packers we've used so far are actually adapters that transform bytes into numbers. They can insert computed values,
encode/decode strings, validate input, etc. Essentially, adapters can carry out any transformation that you wish 
your objects to undergo before packing and unpacking.

## Don't Repeat Yourself: Macros ##
Many times you find yourself in need for a recurring pattern. You could write a full-blown packer/adapter from 
scratch, but why bother? Your best option is to reuse existing building blocks. For instance, Construct attempts 
to define the most general packers and special-case for them concrete usage. One such example is ``Array``, 
which we've met before: Construct defines ``Range``, which will accept a certain minimum up to a certan maximum;
on top of this, ``Array`` is a simple "macro" that expands to a Range with the same minimum and maximum.

{% highlight python %}
def Array(count, itempkr):
    return Range(count, count, itempkr)
{% endhighlight %}

Macros can be more complex, of course. For instance, a recurring pattern is to use a ``Struct`` inside a ``Bitwise``
packer; let's fuse the two into ``BitStruct``:

{% highlight python %}
def BitStruct(*members):
    return Bitwise(Struct(*members))
{% endhighlight %}

<img src="http://tomerfiliba.com/static/res/2012-12-24-great.jpg" class="blog-post-image"/>

Macros have many more uses; you can explore the implementation of Construct to see some examples, and you're 
encouraged to write ones on your own. Remember: less code = great success. As we'll see later on, using macros 
(rather than writing your own packers) can even lead to better performance.

## Putting things in Context ##
So far we've seen simple (static) data structures; but most of the time, there are internal dependencies within
data structures. A very common pattern is a length field: first comes a number, followed by that many units
of data.


## Compilation ##
**NOTE:** This is a work in progess; Construct 3.0 would probably come out with a very basic compiler, which
would be optimized over time.

One of the highlights about Construct is defining your data structures directly in Python. In fact, Construct is an 
in-langaguge [DSL](http://en.wikipedia.org/wiki/Domain-specific_language) in the form of packing combinators: 
instead of expressing your data structures in XML or some 
[proprietary language](https://developers.google.com/protocol-buffers/docs/proto), you just write them (and run them)
as any other piece of code. 

We used to have [psyco](http://psyco.sourceforge.net/), which was capable of speeding up Construct 2 by a tenfold,
but it's been dead for the past four years. I first [had plans](https://sebulbasvn.googlecode.com/svn/trunk/ccon/) 
to compile data structures to C/C++ (which would have made Construct NASA material :)), but I soon realized that its
quite an impossible feat (due to the fact Adapters are Turing-complete).

On the other hand, I now realized I can compile Constructs to Python! The compiler could inspect the whole data 
structure in advance and generate optimized code. Whenever a convertion is not possible, it would just fall back
to the current, interpretted scheme. Here's a sketch:

{% highlight python %}
ipaddr = IpAddress(byte[4])

ipheader = Struct(
    "destination" / ipaddr,
    "source" / ipaddr,
)
{% endhighlight %}

From this definition, we can generate these two functions: 

{% highlight python %}
def ipheader_unpack(stream):
    obj = {}
    obj["destination"] = IpAddress.decode([byte_unpack(1, stream), byte_unpack(1, stream), byte_unpack(1, stream), byte_unpack(1, stream)])
    obj["source"] = IpAddress.decode([byte_unpack(1, stream), byte_unpack(1, stream), byte_unpack(1, stream), byte_unpack(1, stream)])
    return obj

def ipheader_pack(obj, stream):
    out = IpAddress.encode(obj["destination"])
    byte_pack(stream, out[0])
    byte_pack(stream, out[1])
    byte_pack(stream, out[2])
    byte_pack(stream, out[3])
    out = IpAddress.encode(obj["source"])
    byte_pack(stream, out[0])
    byte_pack(stream, out[1])
    byte_pack(stream, out[2])
    byte_pack(stream, out[3])
{% endhighlight %}

Notice there's not recursion and the stack depth remains relatively constant. As the compiler improves, it would 
translate ``byte[4]`` to ``int32ub``, to spead up things.

## Computational Power ##
Here's a semi-proof that Construct is stronger than Context Free languages (as well as 
[Mildly context-sensitive](http://en.wikipedia.org/wiki/Mildly_context-sensitive_language) languages), 
which probably makes it the most powerful (although not the most efficient) parser:

{% highlight python %}
>>> def Match(symbol):
...     return OneOf(Raw(len(symbol)), [symbol])
...
>>> anbncn = byte >> Match("a")[this[0]] >> Match("b")[this[0]] >> Match("c")[this[0]]
>>> anbncn.unpack("\x04aaaabbbbcccc")
[4, ['a', 'a', 'a', 'a'], ['b', 'b', 'b', 'b'], ['c', 'c', 'c', 'c']]
>>> anbncn.unpack("\x04aaaabbbbbcccc")
Traceback (most recent call last):
  ...
construct3.packers.RangeError: Expected 4 items, found 0
Underlying exception: ValidationError("'b' must be in ['c']",)
{% endhighlight %}

Here's a recognizer for the language <img src="http://latex.codecogs.com/gif.latex?na^nb^nc^n" title="na^nb^nc^n" />,
which is not context free (assuming n is given in unary representation, it requires the recognition of 
<img src="http://latex.codecogs.com/gif.latex?1^na^nb^nc^n" title="1^na^nb^nc^n" />). 

## Feedback ##
As Construct 3 is under active development, it's important for me to get user feedback as early as possible. You can
comment right here or drop me a line at <tomerfiliba@gmail.com>.


