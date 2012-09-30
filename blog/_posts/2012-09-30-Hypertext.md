---
layout: blogpost
title: "Hypertext: In-Python Haml"
tags: [python]
published: false
description: "An in-language DSL for generating HTML pages directly in Python, along the lines of Haml"
---

<img src="http://tomerfiliba.com/static/res/2012-09-30-haml.gif" class="blog-post-image" />

<div class="notebox">
<a href="#the-code">TL;DR: Just take me to the code</a>
</div>

I recently got back to web development for some venture I'm working on, which reminded me just how
shitty is the state of the art. There's no nice way to put it: **we're doing web development all 
wrong**. It's not an anecdotal thing I have against this or that: it's the whole. It's a stack of 
inferior technologies, held together by the glues of time, and the sad thing is -- they are here 
to stay. Nobody's gonna kill HTTP or JavaScript, not even Google, at least not in the foreseeable 
future. It's a hand we have to play. 

This isn't new, of course. The last time I did serious web development was back in 2008, on pre-1.0
Django. HTTP requests come and go, but not much has changed. I gathered some early sketches into a 
project called [minima](https://github.com/tomerfiliba/minima) which consisted of only a ``README``
file up until recently. Getting back to web development got be nauseous again and I decided to 
shake off the dust from it, taking it in baby steps.

## Templates? Really?! ##

The first thing that [drives me crazy](http://www.youtube.com/watch?v=-qTIGg3I5y8) when I work on
websites is the use of templates. I hate HTML: it's too low-level and too messy; forgetting to 
close tags properly is too easy, and you have to deal with escaping. Moreover, I hate templating 
languages: they are always cumbersome while being nothing more than a severely crippled version 
of Python. For the record, I tried to deal with these issues back in 2006: 
[templite](http://code.activestate.com/recipes/496702-templite/) - a 60-liner templating engine,
and [HElement](http://code.activestate.com/recipes/496743-helement/) - programmatic representation
of HTML.

The thing that disturbs me the most is, templates are just half-baked way to do function 
application: they take parameters and "plant" them into placeholders in the text. That's called 
β-reduction. Why beat about the bush, let me have real functions. Consider the following Jinja2
code:

    {% extends 'base.html' %}
    {% block content %}
      <ul>
        {% for user in users %}
          <li><a href="{{ user.url }}">{{ user.username }}</a></li>
        {% endfor %}
      </ul>
    {% endblock %}

Note that (1) you write the HTML boilerplate, (2) you have to take care of quoting yourself
(``href="{{ user.url }}"``), and (3), you use a ruby-flavor of Python. What gives? Moreover,
these elusive "blocks" and "extends" are all but function composition. Consider

{% highlight python %}
def base(content):
    return '<html><head></head><body><div class="content">%s</div></body></html>' % (content,)

def my_page(users):
    my_part = ('<ul>' + ''.join('<li><a href="%s">%s<a></li>' % (user.url, user.username) 
        for user in users) + '</ul>')
    return base(my_part)
{% endhighlight %}

Okay, that's ugly, but by now it should be clear that templates are but degenerate Python 
functions, and I'd go with the real thing - thank you.

## <a id="the-code">Hypertext</a> ##

I like [Haml](http://haml.info/) (even though it stemmed in the ruby world :) ). Of course it's 
equivalent to HTML, but I like it's DRY and to-the-point approach. On the other hand, it's 
*yet-another-templating-language*... Arrrgh. 
Enter [hypertext](https://github.com/tomerfiliba/minima/blob/master/hypertext.py)!

The idea of ``hypertext`` is to (1) make your code beautiful, (2) just let you write Python code
and (3) take care of escaping and whatnot for you. Here's the deal:

{% highlight pycon %}
>>> from hypertext import *
>>>
>>> print h1("Welcome", class_="highlight")
<h1 class="highlight">Welcome</h1>

>>> print h1.highlight("Welcome")
<h1 class="highlight">Welcome</h1>

>>> print div.content(h1.highlight("Welcome"), "This is my page")
<div class="content">
    <h1 class="highlight">Welcome</h1>
    This is my page
</div>

>>> with div.content:
...     h1.content("Welcome")
...     TEXT("This is my page")
...
<div class="content">
    <h1 class="highlight">Welcome</h1>
    This is my page
</div>

{% endhighlight %}

And

{% highlight python %}
from hypertext import *

@contextmanager
def base(page_title = "Hello world"):
    with html:
        with head:
            title(page_title)
        
        with body:
            with div.header:
                a(img(src="/img/logo.png"), href="/")
            
            with div.content:
                yield # context-manager
            
            with div.footer:
                TEXT("The content is published under ")
                a("CC-Attribution Sharealike 2.5", href="http://creativecommons.org/licenses/by-sa/2.5/")

def my_page(users):
    with base():
        with ul:
            for user in users:
                with li:
                    a(user.username, href=user.url)

{% endhighlight %}













