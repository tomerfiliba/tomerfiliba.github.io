---
layout: blogpost
title: Deducible UI and UI Combinators
published: false
---

### A Brief History ###

I like automating things. I don't like having to reiterate myself: I always want to be able
to add only the necessary amount of information, in order to make something possible. For instance,
I hate java expressions like `ArrayList<String> x = new ArrayList<String>();`... it always
makes me feel I'm talking to a retard (compiler).

In 2006/7, I wrote some demos for [RPyC](http://rpyc.sf.net), to show how easy tasks become.
I chose something rather complex, a chat client, to show how all the network-related code sums
up to a few lines: clients invoke a method on the server, say `broadcast(str)`, and the server
than invokes callbacks on all of its clients, sending them the message.

In order to make it usable, I had to write a GUI. I chose Tk, because it comes with python
and is quite simple; I knew there were better toolkits, but my GUI was meant to be basic enough
to be doable in any toolkit. Then it occurred to me that I wrote ~20 lines show-casing RPyC
and ~100 lines of GUI, and that something is really wrong here. And by here I mean everywhere.

### GUI Designers ###

So you may say, "Dude, just use QtDesigner or something". A GUI designer lets you visually
place components and makes your life much easier -- drag and drop your GUI, double-click a button
to write its handler. Very easy. But I would like to offer a different angle on the subject:
Just like the Chinese invention of [the teacup](http://www.youtube.com/watch?v=N0OhXxx7cQg)
has hindered their development, so do GUI designers hinder us from developing better GUIs.
These designers offer a local optimum which we fail to overcome, and this leaves us with 
mediocre UIs and development tools.

Think about it: **you** have to design a GUI. For the lion's share of programs, the UI is 
highly straightforward -- there's some information that needs to be displayed to the user,
or gotten from the user, and the *bindings*, so to speak, is trivial. Consider a login screen:
you want to get a username and a password, use them somehow, and proceed to the next screen.
This is a repeating task, and I'd guess that for ~80% of the programs in the world, it's easy 
enough to **automatically deduce** how the UI should look, given the task at hand. And I'm not
talking about machine learning or designing "families" of tasks -- I'm talking about a 
well-defined mapping between programmatic objects and their visual representation.

### Deducing UI ###

Say you have a class, with a set of simple attributes, that you wish to display to
your user. 

{% highlight java %}
class Person {
	public String firstName;
	public String lastName;
	public Date birthdate;
	
	public void 
}
{% endhighlight %}

OK. 








