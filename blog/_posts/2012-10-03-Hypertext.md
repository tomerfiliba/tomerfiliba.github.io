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

{% highlight %}
    {% extends 'base.html' %}
    {% block content %}
      <ul>
        {% for user in users %}
          <li><a href="{{ user.url }}">{{ user.username }}</a></li>
        {% endfor %}
      </ul>
    {% endblock %}
{% endhighlight %}


