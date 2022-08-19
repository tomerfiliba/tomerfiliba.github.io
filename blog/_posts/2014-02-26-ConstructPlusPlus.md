---
layout: blogpost
title: "Construct Plus Plus"
tags: [python, construct]
description: "Implementing surprisingly efficient Pickler Combinators in C++"
imageurl: https://www.tomerfiliba.com/static/res/2012-05-16-construct-logo-small.png
imagetitle: Construct
---

As you may already know, I'm a type-system junkie. My heart yearns for the strongly-typed languages of the world,
but being a I'm a practical guy, I mostly work with Python. That said, I've been keeping myself busy trying to find
a way write a statically-typed version of [Construct](http://construct.readthedocs.org/en/latest/). I started with
Haskell, but quickly gave up when my brain overheated with category theory.

Construct is at least context-sensitive a formalism (I showed in an
[earlier post](https://www.tomerfiliba.com/blog/Survey-of-Construct3/) that it recognizes the languages like ``a^nb^nc^n...z^n``),
which limits one's ability to reason about it (or in my case, embed it in a strongly-type language), but subsets of
Construct are "weak enough" for that. These are known as *Pickler Combinators*, first described (as far as I can tell)
in Andrew Kennedy's [seminal paper](http://research.microsoft.com/pubs/64036/picklercombinators.pdf).

The problem I set to solve was that of a time-and-space efficient, statically-typed RPC between Python and C++.
One approach is to encode types into the data, such as JSON, pickle, or [msgpack](http://msgpack.org/).
Another project of mine, [RPyC](http://rpyc.readthedocs.org/en/latest/), utilizes this method too, and for a dynamic
language that's the most sensible thing to do. But in a richly-typed static language like C++ it would
be a pity to waste both bandwidth and CPU cycles to encode that. It also makes memory management a headache, since
there's no way to tell in advance how much memory would be need (and what types follow). It also requires recursion
(for nested types), and last but certainly not least -- forces you to be dynamically-typed.

The second approach is to have a well-defined IDL, such as [protobuf](https://code.google.com/p/protobuf/) or
[Apache Thrift](http://thrift.apache.org/). This approach, however, requires code generation to run during the
build process (an extra toolchain), and, you know -- another ugly DSL to learn and maintain.

What I'm about to demonstrate here is a serialization mechanism for C++ that relies only on the type system in order
to produce efficient encoding of arbitrarily-complicated objects -- all well-typed and resolved in compile time.
*Protobuf without code generation*, if you wish.

Besides, I've been planning to make use of the new features of [C++11](http://www.stroustrup.com/C++11FAQ.html)
for a while now, so let's bring in the heavy guns!

## Construct++ ##
The basic idea is to have two overloaded template functions for the general case:
* ``void pack(std::ostream&, const T&)``
* ``void unpack(std::istream&, T&)``

And have them specialized for concrete and high-order types. If you're not comfortable with C++11, be sure to
read through the new features because it gets a little scary. Here's how we begin:

{% highlight cpp %}
template<typename T>
typename std::enable_if<std::is_integral<T>::value || std::is_floating_point<T>::value>::type
pack(std::ostream& stream, const T& value) {
    stream.write((char*)&value, sizeof(T));
}

template<typename T>
typename std::enable_if<std::is_integral<T>::value || std::is_floating_point<T>::value>::type
unpack(std::istream& stream, T &value) {
    stream.read((char*)&value, sizeof(T));
}
{% endhighlight %}

These functions handle integers and floating point numbers by packing/unpacking a bitwise representation of the
value to/from the stream. Okay, nothing new here, it's just a casting the value to a ``char*`` and processing
it in the raw. At this point we can write:

{% highlight cpp %}
int16_t v;
unpack(stream, v);
{% endhighlight %}

Big deal.

## Arrays ##

Since we're already dealing with fixed-size data, let's also handle the case of fixed-size arrays
of packable objects:

{% highlight cpp %}
template<typename T, std::size_t N>
void pack(std::ostream& stream, const T (&arr)[N]) {
    for (int i = 0; i < N; i++) {
        pack(stream, arr[i]);
    }
}

template<typename T, std::size_t N>
void unpack(std::istream& stream, T (&arr)[N]) {
    for (int i = 0; i < N; i++) {
        unpack(stream, arr[i]);
    }
}
{% endhighlight %}

Which allows us to write

{% highlight cpp %}
int16_t arr[3][2];
unpack(stream, arr);
{% endhighlight %}

Wha?! We're handling two dimensional arrays here... how's that possible? Well, thanks to the magic of templates,
we can "unwrap" arrays dimension by dimension. We're actually just handling a pair of int16_t three times.
It's all done in compile time of course.

## Variable-Length Data ##

Now let's move on to the more interesting stuff -- variable-length data -- such as vectors:

{% highlight cpp %}
typedef uint8_t length_type;

template<typename T, typename L=length_type>
void pack(std::ostream& stream, const std::vector<T>& vec) {
    L length = (L)vec.size();
    pack(stream, length);
    for (int i = 0; i < length; i++) {
        pack(stream, vec[i]);
    }
}

template<typename T, typename L=length_type>
void unpack(std::istream& stream, std::vector<T>& vec) {
    L length;
    unpack(stream, length);
    vec.resize(length);
    for (int i = 0; i < length; i++) {
        unpack(stream, vec[i]);
    }
}
{% endhighlight %}

It just adds a prefixes of the vector's length (as ``uint8_t``, but you can specify a different type), followed by
the vector's items. Now we can write:

{% highlight cpp %}
vector<uint16_t> vec;
unpack(stream, vec);
{% endhighlight %}

Which takes ``"\x03aabbcc"`` and spews out ``[0x6161, 0x6262, 0x6363]``. Nice already.

## Tuples ##

[Tuples](http://en.cppreference.com/w/cpp/utility/tuple) are a new feature of C++11 that holds a strongly-typed
heterogeneous sequence of objects, as in ``std::tuple<int, char*, float> t(5, "hello", 1.414)``. You can think
of tuples as a light-weight ``structs``, where fields have indexes instead of names.

Iterating over tuples in compile time is a bitch, trust me on that, so I'll skip the full implementation
(hint: it requires recursion) and just say that we have:

{% highlight cpp %}
template<typename... Types> void pack(std::ostream& stream, const std::tuple<Types...>& tup) {
    //...
}
template<typename... Types> void unpack(std::ostream& stream, std::tuple<Types...>& tup) {
    //...
}
{% endhighlight %}

Why do I even bother to show that? The answer will be clear in a moment.

## Structs ##

Structs pose a rather impossible problem for our packing combinators. First of all, not all structs are
packable: they may hold pointers or some internal state that might be transient. But worse, from our perspective,
is the fact that every struct is different... If you wish, "``vector<T>`` are all alike; every struct is a struct in
its own way".

So there's nothing we can do but (a) mark packable structs explicitly and (b) implement a custom pack()/unpack()
semantics for every struct (using inheritance, for example).

{% highlight cpp %}
struct packable {
    virtual void _pack_self(std::ostream& stream) const = 0;
    virtual void _unpack_self(std::istream& stream) = 0;
};

template<typename T>
typename std::enable_if<std::is_base_of<packable, T>::value>::type
pack(std::ostream& stream, const T& pkd) {
    pkd._pack_self(stream);
}

template<typename T>
typename std::enable_if<std::is_base_of<packable, T>::value>::type
unpack(std::istream& stream, T &pkd) {
    pkd._unpack_self(stream);
}
{% endhighlight %}

So we can write

{% highlight cpp %}
struct my_struct : packable {
    uint8_t a;
    uint8_t b;

    void _pack_self(std::ostream& stream) const {
        pack(stream, a);
        pack(stream, b);
    }
    void _unpack_self(std::istream& stream) {
        unpack(stream, a);
        unpack(stream, b);
    }
};

my_struct s;
unpack(stream, s);
{% endhighlight %}

But notice how mechanical the ``_pack_self``/``_unpack_self`` methods are -- we'd really wish to auto-generate
them somehow. We can use a preprocessor macro, but how could we generate a line for each member?
We don't have meta-for-loops after all... or do we? Enter tuples!

{% highlight cpp %}
#define PACKED(...) \
    void _pack_self(std::ostream& stream) const override { \
        auto tmp = std::tie(__VA_ARGS__); \
        pack(stream, tmp); \
    } \
    void _unpack_self(std::istream& stream)  override { \
        auto tmp = std::tie(__VA_ARGS__); \
        unpack(stream, tmp); \
    }
{% endhighlight %}

``std::tie`` builds a strongly-typed tuple of references, meaning they refer to the member variables instead of
holding a copy. Thanks to the power of template programming, packing/unpacking this tuple utlimately boils down
to something like the first version given above -- a line for each member.

So here's the whole deal:

{% highlight cpp %}
struct first_struct : packable {
    uint8_t x;
    uint16_t y;

    PACKED(x, y)
};

struct second_struct : packable {
    uint8_t a;
    std::string b;    // note this is a variable length string!
    int16_t c[3][2];
    first_struct d;
    enum : uint16_t {
        A = 1,
        B = 2,
        C = 3
    } e;

    PACKED(a, b, c, d, e)
};
{% endhighlight %}

Ain't that cool? And it even works!

{% highlight cpp %}
std::stringstream ss;
ss << "A\x05helloa0b0c0d0e0f0Bg0\x02\x00XXXXXXXXXX";
second_struct x = {};
unpack(ss, x);

std::cout << "a=" << (int)x.a << "," << "b=" << x.b << ","
          << "c=" << x.c[0][0] << ".." << x.c[2][1] << ","
          << "d=(" << x.d.x << "," << x.d.y << "),"
          << "e=" << x.e << std::endl;
{% endhighlight %}

Which prints ``a=65,b=hello,c=12385..12390,d=(B,12391),e=2``.

The full code snippet [is available here](https://gist.github.com/tomerfiliba/9216420), tested with ``g++4.8``
and ``clang++3.4`` with ``-std=c++11``.
