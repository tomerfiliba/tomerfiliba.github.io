---
layout: blogpost
title: "Hypertext: In-Python Haml"
tags: [python]
description: "An in-language DSL for generating HTML pages directly in Python, along the lines of Haml"
imageurl: http://tomerfiliba.com/static/res/2012-10-03-haml.gif
imagelink: http://haml.info
---

<div class="notebox">
<a href="#the-code"><strong>TL;DR: Just show me the code</strong></a>
</div>

I recently got back to web development for some venture I'm working on, which reminded me just how
lousy the state of the art is. There's no nice way to put it: **we're doing web development all 
wrong**. It's not an anecdotal thing I have against this or that -- it's every facet of it. It's a 
stack of inferior technologies, held together by the glues of time and legacy. And the sad thing is,
they are here to stay. Nobody's going to kill HTTP or JavaScript, not even Google (at least not 
in the foreseeable future). It's a hand we have to play. 

This isn't new<sup><a href="#foot1" name="foot1back">&#91;1&#93;</a></sup>, of course. The last time I 
did serious web development was back in 2008, on pre-1.0 Django. HTTP requests came and went, but 
nothing really changed. My desperation with the subject has led me to writing the 
[minima manifesto](https://github.com/tomerfiliba/minima/blob/master/README.md)
almost a year ago, but due to my general lack of interest it remained just a README file. Now that 
I'm back in the business, I returned to experiment with it... It won't happen overnight,
but I feel it's within reach.

## Templates? Really?! ##

My first objective is to kill *templates* and *templating engines* - they just
[drive me crazy](http://www.youtube.com/watch?v=-qTIGg3I5y8).
I hate HTML: it's too low-level and verbose; forgetting to close tags properly is too easy, 
and you have to deal with escaping. I like to think of HTML as a serialization format - the
``pickler`` of web pages, rather than something you ought to be messing with directly.

Moreover, I hate templating languages: they are always cumbersome, crippled-down versions of Python,
while providing no added value<sup><a href="#foot2" name="foot2back">&#91;2&#93;</a></sup>. People never 
seem to realize templates are ultimately half-baked function application: they take parameters 
and "plant" them into placeholders in the text. Well, that's called β-reduction, so why beat about 
the bush? Just let us have real functions. Consider the following Jinja2 code:

    {{ "{% extends 'base.html'" }} %}
    {{ "{% block content" }} %}
      <ul>
        {{ "{% for user in users" }} %}
          <li><a href="{{ "{{ user.url" }} }}">{{ "{{ user.username" }} }}</a></li>
        {{ "{% endfor" }} %}
      </ul>
    {{ "{% endblock" }} %}

Note that (1) you write the HTML boilerplate (and closing tags), (2) you have to take care of 
quoting yourself (notice the quotes in ``href="{{ "{{ user.url"}} }}"``), and (3), you use a 
ruby-flavor of Python. What gives? Moreover, these elusive "blocks" and "extends" are all but 
function composition. Here's the functional alternative:

{% highlight python %}
def base(content):
    return ('<html><head></head><body><div class="content">' + 
        content + '</div></body></html>')

def my_page(users):
    my_part = ('<ul>' + ''.join(
        '<li><a href="%s">%s<a></li>' % (user.url, user.username) 
            for user in users) + '</ul>')
    return base(my_part)
    
# Or with composition, ``base . my_page``
{% endhighlight %}

Okay, that looks terrible, no question about it. Nonetheless, it should be clear by now that 
templates are simply degenerate functions.

## Haml ##

I like [Haml](http://haml.info/), even though it originated in the ruby world ;) In case you're
not familiar with it, it's a more concise and to-the-point way to write HTML. Haml is basically a
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

On the other hand, in case you missed the ``<%= print_date %>``, Haml is *yet-another templating
language*... arrrgh! 

<a name="the-code"></a>

## Hypertext ##

During my experimentation with ``minima``, I wrote 
[hypertext](https://github.com/tomerfiliba/minima/blob/2e7b0dacf056ff06c39966f970955910735a8260/hypertext.py)
- a Pythonic a Hamlian way to write "HTML functions". Hypertext aims to:

1. be (almost) as concise as Haml
2. make your code beautiful and easy to read, by reflecting the structure of the HTML
3. make exceptions easy to locate, with meaningful tracebacks
4. give you the full power of Python directly (with existing *lint* capabilities straight out of
   your IDE). Down with template files all over the place!
5. take care of escaping and whatnot for you

The ultimate goal is to make your page *semantic*, but it will take some time to get there. 
In the meanwhile, ``hypertext`` is like an intermediate representation. Anyhow, generating 
HTML is really simple:

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

But the key-feature of ``hypertext`` is the use of elements as *context managers*:
{% highlight pycon %}
>>> with div.content:
...     h1.highlight("Welcome")
...     TEXT("This is my page")
...
<div class="content">
    <h1 class="highlight">Welcome</h1>
    This is my page
</div>
{% endhighlight %}

This lets your procedural code reflect the structure of your document, while you can use 
``for``-loops, ``if`` statements, or call functions right inside it. 

It should be noted that ``hypertext`` is a **[DSL](http://en.wikipedia.org/wiki/Domain-specific_language) 
within Python**, which puts wrist-handiness before implementation purity, so it cuts itself
some slack when it comes to **magic**. For instance, ``div`` is a class, but ``div.content`` 
actually translates to ``div().content`` through the use of metaclasses; the same goes for 
``with div:`` that translates ``with div():``. For convenience, ``div.foo.bar()`` is identical to 
``div.foo().bar`` as well as to ``div().foo.bar``. 

Moreover, there's a thread-local stack of elements behind the scenes, so when new elements 
are created, they're automagically added as children of the top-of-stack element. This works the 
same way as flask's [global request object](http://flask.pocoo.org/docs/quickstart/#context-locals).
Utilizing the stack, ``TEXT`` appends some text to the ToS element; along with it are ``UNESCAPED``
(which appends unescaped/raw text) and ``ATTR`` (which sets attributes of the ToS element).

This touch of magic lets us write idiomatic, well-structured and easy-to-debug code:

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
                yield root      # it's a context manager
                
            with div.footer:
                TEXT("The content is published under ")
                a("CC-Attribution Sharealike 2.5", 
                    href="http://creativecommons.org/licenses/by-sa/2.5/")

@app.route("/blog/<postid>")
def blog_post(postid):
    post = Post.get(postid)
    
    with base_page(post.title) as root:
        h1(post.title)
        div.datebox(post.date.strftime("%Y-%m-%d"))
        with div.main:
            UNESCAPED(post.body)
        
        for comment in post.comments:
            with div.comment_box:
                div.comment.author(comment.author)
                div.comment.text(comment.text)

    return str(root)
{% endhighlight %}

**Voila**. As I explained, my real intent is to write semantic code and not worry about concrete 
HTML elements, their classes or ensuring the uniqueness of their IDs. Besides, the way I see it, 
displaying a blog post would be sending an HTML template + JavaScript code to the client once, 
which would fetch individual posts over JSON APIs. This makes your site service-oriented and much
easier to write unittests for.

----------

1. <a name="foot1"></a>For the record, I tried to deal with these issues back in 2006: 
   [templite](http://code.activestate.com/recipes/496702-templite/) - a 60-liner templating engine
   that has given rise to a [successor](http://www.joonis.de/content/TemplitePythonTemplatingEngine),
   and [HElement](http://code.activestate.com/recipes/496743-helement/) - programmatic representation
   of HTML. See also [BlazeHtml](http://jaspervdj.be/blaze/). 
   <sup><a href="#foot1back" title="back">&#x21D1;</a></sup>

2. <a name="foot2"></a>A note on *sandboxing*: since Jinja2 compiles templates to Python bytecode, 
   the same mechanisms can be used here, if desired. Anyway, I won't evaluate untrusted templates 
   this way or the other... even something as innocent as ``<b>{{ "{{ user.username" }} }}</b>`` 
   invokes an overridible ``__getattr__``. As explained at the end of the post, using a 
   service-oriented web site means you don't render templates but expose APIs, so there's no need 
   to evaluate untrusted templates. 
   <sup><a href="#foot2back" title="back">&#x21D1;</a></sup>

