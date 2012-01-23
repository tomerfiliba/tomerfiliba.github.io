---
layout: recipe-page
title: HTML Codec
---

A very simple and straight-forward text/HTML codec. When encoding text, it escapes all 
HTML-delimiters (`<` becomes `&lt;`, etc.), so the encoded text can be safely viewed by an 
HTML renderer (browser) or safely embedded into an HTML document. When decoding HTML, it 
un-escapes the formatters into plain text (so that `&gt;` becomes `>` again, etc.).

## Code ##

{% highlight python %}
def encode(input, tabsize = 4):
    return (input
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;")
            .replace("\n", "<br/>")
            .replace("\t", "&#9;" + " " * tabsize)
            .replace(" ", "&nbsp;"))

def decode(input, tabsize = 4):
    return (input
            .replace("&nbsp;", " ")
            .replace("&#9;" + " " * tabsize, "\t")
            .replace("<br>", "\n")
            .replace("<br/>", "\n")
            .replace("&quot;", '"')
            .replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&amp;", "&"))

#
# Codec APIs (if you place this file in lib/encodings, you can use 
# str.encode("html") and str.decode("html")
#
import codecs

class HtmlCodec(codecs.Codec):
    def __init__(self, tabsize = 4):
        self.tabsize = tabsize
    def encode(self, input, errors = "strict"):
        return encode(input, self.tabsize), len(input)
    def decode(self, input, errors = "strict"):
        return decode(input), len(input)

class StreamWriter(HtmlCodec, codecs.StreamWriter):
    pass
class StreamReader(HtmlCodec, codecs.StreamReader):
    pass
def getregentry():
    hc = HtmlCodec()
    return (hc.encode, hc.decode, StreamReader, StreamWriter)
{% endhighlight %}

## Example ##

This module can be used as a standalone module

{% highlight pycon %}
>>> import htmlcodec
>>> htmlcodec.encode("blah > yada")
'blah&nbsp;&gt;&bnsp;yada"
{% endhighlight %}

Or you can place it in your interpreter's {{lib/encodings}} directory, as {{html.py}} for instance, and then use

{% highlight pycon %}
>>> '(blah > yada) & "wow"\ni eat babies'.encode("html")
'(blah&nbsp;&gt;&nbsp;yada)&nbsp;&amp;&nbsp;&quot;wow&quot;<br/>i&nbsp;eat&nbsp;babies'
>>> _.decode("html")
'(blah > yada) & "wow"\ni eat babies'
{% endhighlight %}
