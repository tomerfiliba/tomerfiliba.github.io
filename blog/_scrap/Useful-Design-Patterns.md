---
layout: blogpost
title: Some Useful Design Patterns
published: false
description: 
tags: [python]
---

I wanted to diverge a little from the topics I've been covering recently (DSLs, GUIs, etc) into 
the more theoretical-but-practical grounds of design patterns. I'm sure you've heard about them
before, but I'd like to offer my view on the subject and highlight some of the patterns that I 
find the most useful. Although design patterns go hand-in-hand with the object-oriented methodology, 
which I think less of, they are useful on their own as they tend to capture generalizations.

<a href="http://dryicons.com/free-graphics/preview/flower-pattern/">
<img src="http://tomerfiliba.com/static/res/2012-03-03-flower_pattern.jpg" style="float: right; width: 250px;" title="Flower pattern" /></a>

## Null, State, Strategy and RAII ##

I'll begin with a bold claim: I don't distinguish between the [Null](http://en.wikipedia.org/wiki/Null_Object_pattern),
[State](http://en.wikipedia.org/wiki/State_pattern) and [Strategy](http://en.wikipedia.org/wiki/Strategy_pattern)
patterns. I see them as different projections of the same basic idea: don't rely on hard-coded 
`if`/`switch` statements to determine your flow; instead, move the runtime behavior to an external 
object. This makes your code more modular (easier to extend) and concise (shorter), at virtually
zero-cost.

*State* and *Strategy* are the "big gun" brothers of *Null*, but the idea, as I said, is the same.
Before going into an example, allow me to call yet another pattern into the arena: 
[RAII](http://en.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization), or *Resource Acquisition
is Initialization*. This pattern is well known and widely used in the C++ world, but it's has less
PR outside of it, mostly because C++ lacks the `try`-`finally` clause that other languages have.
In short, RAII says you should "fully-initialize" the object at construction time, and put any
cleanup (`finally`) code in the destructor, because that's the only way to guarantee it will take
place in case of an exception. For instance, instead of first initializing an unopened `File` object
and then calling open() on it, have the constructor open the file at initialization. This way,
the lifespan of the *object* and the lifespan of the *resource* it represents are one.

Okay, why would be want to use RAII in a language like Python or Java? Well, in short, you wouldn't.
But you would like to borrow an idea from it: allocate resources at construction time. Linking the 
lifespan of the object and the resource it holds is a good practice. Since we're using a
garbage-collected language with support for `finally` clauses, we needn't bother ourselves with 
deallocation too much, and besides, that's what [context managers](http://www.python.org/dev/peps/pep-0343/) 
are for.




Suppose you have a resource, e.g., a file or network stream. 

Python's `file` type is an excellent example of this: you cannot just create an unopened file,



## Visitor, Polymorphism and Double-Dispatch ##
Polymorphism in object-oriented languages is achieved through the notion of *single dispatch*, 
which basically means you have many "versions" for a function, and you choose which one to invoke 
based on the runtime type of the first (`this`) argument. This way, 
`Animal x = getAnimal(); x.eat("banana")` would invoke `Cow.eat` if `x` is a `Cow` or `Dog.eat` 
if `x` is a `Dog`. This idiom is usually expressed by a dedicated syntax (`obj.method()`), 
but it's conceptually identical to `eat(who, what)`. In reality, the first argument (the instance)
holds a *vtable* containing the version of `eat()` applicable to this instance, so it's more like
`obj->vtable[METHOD_EAT](obj, "banana")`, but let's no dwell on technicalities.

Come to think of it, polymorphism is closely related to **function overloading**; the only difference 
being that overloading is resolved at *compile time*, while polymorphism takes place at runtime. 
Also, object oriented polymorphism is polymorphic only on the first argument, while overloading 
matches any number of arguments. Going back to the our little example, how can I specify a different
behavior (read: *method*) when a cow eats hay (gives milk) or meet (goes mad)? Can I prevent dogs
from eating bananas? If the set of foodstuffs is close, I can hardcode all the choices (either 
using method overloading or the nasty `if (x instanceof y)` boilerplate). But what could I do
if the set is not known in advance? How would I react to dogs eating marshmallows?

For this, you'd need [double dispatch](http://en.wikipedia.org/wiki/Double_dispatch): the ability
to invoke the correct function based on the runtime type of (the first?) *two* arguments. 
Enter **visitor**.

The [visitor](http://en.wikipedia.org/wiki/Visitor_pattern) pattern is usually employed when 
you need to traverse complex data structures like trees (e.g., [AST](http://en.wikipedia.org/wiki/Abstract_syntax_tree)).
It allows you to separate the walking-the-tree part from the performing-actions-on-nodes part,
but it's actually a mechanism for double-dispatch over single-dispatch. Here's how we'd use a 
visitor to double-dispatch `eat`-ing:

{% highlight java %}

class Foodstuff {}
class Meet extends Foodstuff {}
class Hay extends Foodstuff {}
class Banana extends Foodstuff {}

class AnimalFoodVisitor {
    void eat(Cow who, Hay what) {
        // ...
    }
    void eat(Cow who, Meet what) {
        // ...
    }
    void eat(Dog who, Meet what) {
        // ...
    }
    void eat(Dog who, Banana what) {
        // ...
    }
}


class Animal {
    void eat(AnimalFoodVisitor visitor, Foodstuff f) {
        visitor.eat(this, f);
    }
}

{% endhighlight %}



So what


 





## Multiple Dispatch ##

http://en.wikipedia.org/wiki/Dynamic_dispatch















