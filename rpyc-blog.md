---
layout: default
section: blog
title: RPyC Development Blog
description: RPyC Development Blog
feed_link: /blog/rpyc-atom.xml
---

{% assign filtered_posts = site.categories.blog %}

<table style="border:none; width:100%;">
{% for post in filtered_posts %}
{% if post.tags contains "rpyc" %}
{% unless post.draft %}
<tr style="height: 4.5em;">
    <td style="text-align:left"><a href="{{ post.url }}" class="blog-title">{{ post.title }}</a></td>
    <td style="text-align:right"><em>posted on {{ post.date | date: '%B %d, %Y' }}</em></td>
</tr>
<tr>
    <td colspan="2" style="blog-excerpt">
    {{ post.content | strip_html | truncatewords: 30 }}
    </td>
</tr>
{% endunless %}
{% endif %}
{% endfor %}
</table>
