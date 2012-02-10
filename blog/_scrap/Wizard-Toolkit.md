---
layout: blogpost
title: Wizard Toolkit
tags: [python]
---

Following my [Deducible UI post](http://tomerfiliba.com/blog/Deducible-UI), and following some of the criticism it had 
received, I'd like to share something I've been working on (read: *experimenting with*) at my work 
place. You see, we have some "interactive wizards" that storage admins use to connect storage arrays 
to their hosts (say, a DB server). These wizards prompt you with questions like your username,
the name of the pool/volume, whether it's an iSCSI or a Fiber Channel connection, etc., and then
they go and perform what you've asked for.

These wizards operate in a terminal environment, but we've had thoughts to make GUI/web versions
of them. This would be a considerable effort with the current design. Another issue they currently 
have is mixing "business logic" and presentation together. For instance, the code that scans the 
devices attached to your host also prints ANSI-colored messages or reports its progress. All in 
all it works fine, but there's lots of room for improvement.

I began to investigate this corner a month or two ago. The initial observation was that such wizards
have a pretty rigid and repetitive structure, thus we can find some abstraction or a "toolkit" for 
"expressing" wizards more compactly. This has also led to the realization that once the business 
logic and presentation are separate, there's no reason to limit ourselves to terminal-based interaction: 
our wizard-toolkit could do the plumbing and work with terminals, GUIs, web-browsers, etc. 
The business logic would remain oblivious of this, and we could have a nice GUI at zero-cost! 
And last but not least, there was also the issue of *styling*, i.e., printing colored text, 
that I wanted to get rid of.

The styling part was easy: I thought, why not employ the model of HTML and CSS? Let's separate the 
structure (semantics) of the text from its styling. Instead of printing a banner for titles, 
we'll display a `Title` object, whose exact appearance is determined by a "style sheet". 
For instance, when we're using a color-enabled terminal, the title would be printed in bold and 
followed by an empty line; but if our terminal is color-blind, we'll render the text centered and 
surrounded by `=` marks. Another example is error-handling: instead of printing error message 
in red every time, we'll display an `Error` object; on a terminal, this would be rendered as 
red text, but when running in a GUI, rendering this object would pop up a message box. 
I'm going to ignore this for the rest of this post, as this is really a solved issue.

Now let's get to expressing wizards, or more generally, *dialogs*. A dialog is a "container object"
that's made of *dialog elements*. These elements can be output-only (such as a welcome message), or 
input-output (such as an message telling you to choose one of the available options). A dialog
is "executed" by a `DialogRunner` that renders it and returns the results (user inputs).
It's quite important to note that dialog elements within a single dialog cannot be interdependent --
that is, if you want to ask the user for his name and then show `"Hi there %s"` with the user's
name, this has to be done as two, serial dialogs.

That was quite a lot of babble -- let's see this in action:

{% highlight python %}
class MyApp(WizardApp):
    def main(self):
        iscsi = Option("iSCSI")
        fc = Option("FC")
        d = Dialog(
            Text(Title("hello world")),
            Input("un", "Username"),
            Password("pw", "Password"),
            Choice("conf", "What do you want to configure?", [iscsi, fc]),
        )
        res = self.ui.run(d)
        if res["conf"] == fc:
            self.config_fc(res)
        else:
            self.config_iscsi(res)
    ...

if len(sys.argv) == 2 and sys.argv[1] == "--gtk":
    MyApp.run(GtkDialogRunner(MyApp.__name__))
else:
    MyApp.run(TerminalDialogRunner(ANSIRenderer))
{% endhighligt %}

It's a short and incomplete snippet of course, as I'm only going to cover the big picture. The 
`main` function creates a dialog object `d` and passes it to `ui.run`, which "runs" the dialog
and returns the results, as a dictionary. Notice that the dialog elements `Input`, `Password`
and `Choice` all take a first parameter -- this is the key under which the result would be placed
in the returned dictionary, e.g., `res["un"]` would hold the user-provided user name, and 
`res["pw"]` would hold the password. `Text`, on the other hand, is an output-only element, 
so it doesn't return anything and doesn't take a key. Long story short, we're asking the user 
to enter some information and choose from two options, and then continue processing based on the 
selected option. At the bottom, we determine how to run the application based on a command-line 
switch: if `--gtk` is given, we'll run the dialogs through the `GtkDialogRunner`; otherwise, 
we'll use the `TerminalDialogRunner`.

And how does it look like? When running on a terminal:

<a href="http://tomerfiliba.com/static/res/2012-02-11-wizard-terminal.png">
<img src="http://tomerfiliba.com/static/res/2012-02-11-wizard-terminal.png" 
title="Running as a GTK application" width="100%" /></a>

And with a single command-line switch, we run as GTK application:

<a href="http://tomerfiliba.com/static/res/2012-02-11-wizard-gtk.png">
<img src="http://tomerfiliba.com/static/res/2012-02-11-wizard-gtk.png" 
title="Running in a terminal" width="100%" /></a>

So of course it's far from perfect, but then again, it's a small research project I've only put
~15 hours into. It suffers from some of the problems I've listed in the deducible UI post, for 
instance, the GUI hangs when the "business logic" performs blocking tasks. This could be solved
by moving to a reactor-based model, but I've tried to keep the existing wizard code in tact as 
must as possible. A hanging GUI is not nice, but it's not the end of the world either, and 
there are numerous ways to overcome this.

Another benefit this design brings along is the ability to automate testing by using "mock" dialog 
runners. Since our business logic is only exposed to the returned dictionary, we can use a
dialog runner that actually displays nothing and returns a scripted scenario. We can even go 
further: because our business logic "talks" in high-level primitives like `Choice`, we can compute 
the Cartesian product of all choices and run through each of them. We can show that we've 
covered all paths! And we can do this automatically... no more need for people to hit buttons 
and keep logs of their progress.

Anyway, I just wanted to show that it's feasible.

