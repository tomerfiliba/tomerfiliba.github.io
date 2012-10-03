---
layout: blogpost
title: "Hypertext: In-Python Haml"
draft: true
description: "An in-language DSL for generating HTML pages directly in Python, along the lines of Haml"
---

<img src="http://tomerfiliba.com/static/res/2012-10-03-haml.gif" class="blog-post-image" />

<div class="notebox">
<a href="#the-code">TL;DR: Just take me to the code</a>
</div>

I recently got back to web development for some venture I'm working on, which reminded me just how
shitty the state of the art is. There's no nice way to put it: **we're doing web development all 
wrong**. It's not an anecdotal thing I have against this or that -- it's every facet of it. It's a 
stack of inferior technologies, held together by the forces of time, and the sad thing is, they are 
here to stay. Nobody's gonna kill HTTP or JavaScript, not even Google, at least not in the 
foreseeable future. It's a hand we have to play. 


This isn't new [&#91;1&#93;](#foot1), <a name="foot1back"></a> of course. The last time I did serious web development was 
back in 2008, on pre-1.0 Django. HTTP requests came and went, but nothing really changed. My 
desperation with the subject has led me to write the 
[minima manifesto](https://github.com/tomerfiliba/minima/blob/master/README.md)
almost a year ago, but due to my general lack of interest it remained a README file. Now that I'm
back in the business, I thought of reviving my experimentations with it. It won't happen overnight,
but I feel it's within reach.

## Templates? Really?! ##

My first objective is killing *templates* and *templating engines* - these just
[drive me crazy](http://www.youtube.com/watch?v=-qTIGg3I5y8).
I hate HTML: it's too low-level and too messy; forgetting to close tags properly is too easy, 
and you have to deal with escaping. I like to think of HTML as a serialization format - the
``pickler`` of web pages, rather than something you ought to be messing with directly.

Moreover, I hate templating languages: they are always cumbersome, crippled-down versions of Python,
while providing no added value [&#91;2&#93;](#foot2). <a name="foot2back"></a> People never seem to 
realize templates are basically half-baked function application: they take parameters and "plant" 
them into placeholders in the text. Well, that's called β-reduction, so why beat about the bush? 
Just let us have real functions. Consider the following Jinja2 code:

```
{% extends 'base.html' %}
{% block content %}
  <ul>
    {% for user in users %}
      <li><a href="{{ user.url }}">{{ user.username }}</a></li>
    {% endfor %}
  </ul>
{% endblock %}
```

Note that (1) you write the HTML boilerplate (and closing tags), (2) you have to take care of 
quoting yourself (notice the quotes in ``href="{{ user.url }}"``), and (3), you use a ruby-flavor 
of Python. What gives? Moreover, these elusive "blocks" and "extends" are all but function 
composition. Here's the functional alternative:

{% highlight python %}
def base(content):
    return '<html><head></head><body><div class="content">' + content + '</div></body></html>'

def my_page(users):
    my_part = ('<ul>' + ''.join('<li><a href="%s">%s<a></li>' % (user.url, user.username) 
        for user in users) + '</ul>')
    return base(my_part)
{% endhighlight %}

Okay, that's terrible, no question about it. Nonetheless, it should be clear by now that templates 
are but degenerate functions.

## Haml ##

I like [Haml](http://haml.info/), even though it originated in the ruby world ;) In case you're
not familiar with it, it's a more concise, to-the-point way to write HTML. Haml is basically a
preprocessor that expands "macros" to their verbose HTML equivalent. For instance, the Haml code 
to the left generates the HTML code to the right:

    #profile                            |  <div id="profile">
      .left.column                      |    <div class="left column">
        #date= print_date               |      <div id="date"><%= print_date %></div>
        #address= current_user.address  |      <div id="address"><%= current_user.address %></div>
      .right.column                     |    </div>
        #email= current_user.email      |    <div class="right column">
        #bio= current_user.bio          |      <div id="email"><%= current_user.email %></div>
                                        |      <div id="bio"><%= current_user.bio %></div>
                                        |    </div>
                                        |  </div>

On the other hand, in case you missed ``<%= print_date %>``, Haml is *yet-another templating
language*... Arrrgh. 

<a name="the-code"></a>

## Hypertext ##

So I wrote [hypertext](https://github.com/tomerfiliba/minima/blob/master/hypertext.py), aiming
to   

1. make your code beautiful, by making it reflect the structure of the HTML
2. make exceptions easy to locate
2. give you the full power of Python directly (and existing *lint* capabilities) without introducing
   yet another limited templating language
3. take care of escaping and whatnot for you. 

The ultimate goal is to make your page *semantic*, but it will take some time to get there. 
In the meanwhile, here's a simple demonstration of ``hypertext``'s power. Generating HTML is easy:

{% highlight pycon %}
>>> from hypertext import *
>>>
>>> print h1("Welcome", class_="highlight", id="foo")
<h1 class="highlight" id="foo">Welcome</h1>
{% endhighlight %}

And you've got Haml-style shortcuts for wrist-handiness - dot-notation can be used to add classes 
to the element:

{% highlight pycon %}
>>> print h1.highlight("Welcome", id="foo")
<h1 class="highlight" id="foo">Welcome</h1>
{% endhighlight %}

Naturally, elements may be nested:

{% highlight pycon %}
>>> print div.content(h1.highlight("Welcome"), "This is my page")
<div class="content">
    <h1 class="highlight">Welcome</h1>
    This is my page
</div>
{% endhighlight %}

But the pinnacle of ``hypertext`` is the use of elements as *context managers*:
{% highlight pycon %}
>>> with div.content:
...     h1.content("Welcome")
...     TEXT("This is my page")
...
<div class="content">
    <h1 class="highlight">Welcome</h1>
    This is my page
</div>
{% endhighlight %}

This lets your procedural code reflect the structure of your document. It should be noted that 
``hypertext`` is a [DSL](http://en.wikipedia.org/wiki/Domain-specific_language) within Python,
and puts wrist-handiness before implementation purity, and therefore **it allows itself to use 
some magic**. For instance, ``div`` is a class, but ``div.content`` actually translates to 
``div().content``; the same goes for ``with div:`` that translates ``with div():``. For 
convenience, ``div.foo.bar()`` is identical to ``div.foo().bar`` as well as ``div().foo.bar``.
Moreover, there's always a "stack" of elements behind the scenes, so when new elements are 
created, they're automagically added as children of the top-of-stack element. This works in the 
same spirit of [flask's request](http://flask.pocoo.org/docs/quickstart/#context-locals) object.
Likewise, ``TEXT`` is special function that appends some text to its parent.

This sprinkle of magic lets us write idiomatic, well-structured and easy to debug code:

{% highlight python %}
from hypertext import body, head, div, title, a, img, h1, span, TEXT

@contextmanager
def base_page(the_title, the_content):
    with html as root:
        with head:
            title(the_title)
        
        with body:
            with div.header:
                a(img(src="/img/logo.png"), href="/")
            
            with div.content:
                yield root      # it's a content manager
                
            with div.footer:
                TEXT("The content is published under ")
                a("CC-Attribution Sharealike 2.5", href="http://creativecommons.org/licenses/by-sa/2.5/")
    
    return str(html)

@app.route("/blog/<postid>")
def blog_post(postid):
    post = Post.get(postid)
    
    with base_page(post.title):
        h1(post.title)
        div.datebox(post.date.strftime("%Y-%m-%d"))
        with div.main:
            UNESCAPED(post.body)
        
        for comment in post.comments:
            with div.comment_box:
                div.comment.author(comment.author)
                div.comment.text(comment.text)
{% endhighlight %}

Voila. As I explained, my real intent is to write semantic code and not worry about concrete HTML 
elements, their classes or their IDs.

----------

1. <a name="foot1"></a>For the record, I tried to deal with these issues back in 2006: 
   [templite](http://code.activestate.com/recipes/496702-templite/) - a 60-liner templating engine,
   and [HElement](http://code.activestate.com/recipes/496743-helement/) - programmatic representation
   of HTML. [Back](#foot1back)

2. <a name="foot2"></a>A note on *sandboxing*: since Jinja2 compiles templates to Python bytecode, 
   the same mechanisms can be used here, if desired. Anyway, I won't evaluate untrusted templates 
   this way or the other... even something as innocent as ``<b>{{ user.username }}</b>`` invokes 
   a custom ``__getattr__``. [Back](#foot2back)

