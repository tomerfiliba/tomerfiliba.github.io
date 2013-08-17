---
layout: etc-page
title: Travolta NXT
description: University Lego NXT project
imagepreview: http://tomerfiliba.com/static/res/2013-04-14-lego.png
---

## Abstract ##

*Travolta NXT*, the dancing robot, reads color-coded dance instructions from a strip of paper and then performs the
dance, in front of the astonished audience.

## Modus Operandi ##

1. Travolta starts (and waits 3 seconds for the console to connect)
2. It begins by reading color-coded dance moves from a strip of paper. In order not to go astray, the robot
   will follow the black guiding line, until a black color strip is reached. This marks the end of the instructions.
   Before reaching black, each pair of colors encodes a dance move, one of ``forward``, ``backward``, 
   ``turn right``, ``reversed turn right``, ``turn left`` and ``reverse turn left``
3. When it reaches black, the robot stops and waits for the music to begin (the sound sensor reporting a value over 50)
4. When the music starts, Travolta begins to dance: each dance move is executed for 1 second, and then the next one
   is carried out.
5. When all instructions have been consumed, it waits 2 seconds and shuts down.

## Code ##

The code for the project can be found at <https://github.com/tomerfiliba/nxt-dancer/tree/modelmaster/models>.
This repository contains two branches, ``master`` and ``modelmaster``. The first is the implementation of the robot
directly over Lejos, while the latter uses our component language. A short comparison of the two follows.

## Components ##

Due to the difficulties with the component language (see discussion below), Travolta is not as "neatly componentized"
as I had hoped. It consists of the main ("brain") component, which holds all of the "business logic", and several 
components for sensors and motors. The brain employs an internal state machine to do its work in iterations.

![Component model](http://tomerfiliba.com/static/res/2013-04-14-model.gif)

I aimed for a more modular design, where a Reader component would read the instruction, a Dancer component would 
carry them out, etc., but it proved too complicated to implement.

## Running Example ##

<iframe width="640" height="360" src="http://www.youtube.com/embed/xGVTNrVDF2I?feature=player_detailpage" frameborder="0" allowfullscreen></iframe>

## Critical Analysis of the Component Language ##

Before implementing the robot in the [component language](http://www.cs.tau.ac.il/~eranhaba/SMLAB/index.htm)
developed by Eran and Ido, I thought I'd get some hands-on experience with Lejos directly. It proved quite easy,
and within two hours and 300 LoC I got the project up and running. It was divided into a reader-loop that read 
instructions from the paper strip and a dancer-loop that executed the dance moves.

When I set off implementing the robot using the component language, I began to realize it just doesn't fit my needs.
Being component-oriented perhaps borrows from other low-level, embedded languages like VHDL, but it just didn't 
capture the right abstraction for my project. Simply put, my code had *control flow*, starting at A, moving to B and 
then to C. Trying to view each step as a component was artificial and didn't really work.

Moreover, the expressive power provided by the component language is that of a finite state automaton (FSA).
In order to read instructions and act on them, I had to have some sort of *memory*, which requires something 
equivalent to a pushdown automaton (PDA). Solving this required either implementing a "queue component" into which
I could push values and later on pop them, or just going "full Java" and implementing the ``compute`` method
directly. While the first approach was feasible, it didn't fit my deadline, and managing the entire state machine
of the robot as an FSA required too many states, which made things impossible to follow and debug.

Therefore, I resorted to implementing the ``compute`` method myself and writing my "business logic" in Java,
where I could make use of ``ArrayList`` and other data structures; essentially, the only benefit I got form the
component runtime was the "main loop" and the Escape button being handled externally. The result was 550 LoC (of
both ``cmp`` and Java code) and required two days to implement and debug.

I would also like to note that other projects done in the component language, like the Platoon robots,
have a single component with a "huge state machine" to manage their state; it seems that control flow in the 
component language can hardly be modular, which has led me to the conclusion that it's simply not the 
right abstraction for most projects.

## Issues with the Physical World ##

* The color sensor reads colors almost randomly. It may say that red is yellow or vice versa, for no apparent reason.
  I just had to live with it.
* At first I was naive and thought that operating the two motors at the same speed would make the robot go 
  straight line, but it went astray quite soon. Therefore, I made the robot follow the black line while reading 
  instructions.

## Small Bug in the Component Language ##

The code that's generated for the main component (marked with ``<<Deploy>>``) doesn't call the right Java 
implementation; it will call ``XXX`` and not ``XXXImpl`` even if it exists. I had to fix it manually in the 
generated ``TravoltaFactory``.

