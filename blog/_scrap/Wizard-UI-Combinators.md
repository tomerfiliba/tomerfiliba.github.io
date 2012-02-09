---
layout: blogpost
title: Wizard UI Combinators
---

Following my [/blog/Deducible-UI] post, and following some of the criticism it had received, I'd
like to share something I've been working on (read: *experimenting with*) at my workplace. You see,
we have some "interactive wizards" that storage admins use to connect a storage array to their
hosts (a DB server, for instance). These wizards prompt you with questions like your username,
the name of the pool/volume, whether it's an iSCSI or a Fiber Channel connection, etc., and then
they go and perform what you've asked for.

These wizards operate in a terminal environment, but we've had thoughts to make GUI/web versions
of them. Another issue they currently have is mixing "business logic" and presentation together.
For instance, the code that scans the devices attached to your host also prints ANSI-colored 
messages or reports its progress. All in all it works fine, but there's lots of room for 
improvement.

I began to investigate this corner a month or two ago. The initial observation was that such wizards
have a pretty rigid, repeating structure, and we can find some better "toolkit" for creating 
wizards. This has also led to the realization that once the business logic and presentation are
separated, there's no reason to be limited to terminal-based interaction: our wizard-toolkit
could work with  

. Another realization was that
there's no reasons that the code would be 


First, I wanted to separate the presentation
from the business logic. This itself divided into two parts: *styling* and *dialogs*. The second
goal was to make this code GUI-able at zero-cost. The initial observation that has led to this 
research was that wizards have a fairly rigid structure of prompting the user for inputs and 
then taking the right actions. Their "interactiveness" is limited to when the user makes his 
choices, and beyond that point, they are 


