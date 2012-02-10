---
layout: default
section: blog
title: Blog Posts
feed_link: http://tomerfiliba.com/blog/atom.xml
---

{% assign filtered_posts = site.categories.blog %}

{% include pagelist.html %}

