# Tower of Psych #

"Tower of Psych", or "tops", is a code project started by Ben Heasly in July of 2009.  It aims to facilitate the design and running of psychophysics experiments in Matlab

The idea is that a lot of psychophysics experiments have a lot of organization in common, and this organization should be factored into well-behaving classes with handy graphical interfaces.

This document is intended as a tops survey and introduction.  It discusses the motivation for the tops "foundation" classes, some high-level philosophies and design choices of tops, and some of the Matlab concepts that tops builds on.

A good follow-up to this document would be "encounter-as-tops-demo.rtf".  It explains the "encounter" game, which is a demo that comes with tops.  encounter synthesizes all the tops foundation classes into a game that is similar to a psychophysics experiment. (not done yet...)


# tops foundation #
The basis of the Tower of Psych is a group of four classes called the "tops foundation".  These classes should support the most common requirements of psychophysics experiments.  They should also reveal their contents and actions with built-in graphical interfaces.

### TREE-LIKE ORGANIZATION ###
Many psychophysics experiments require some big initial setup, followed by smaller setup steps that are specific to individual tasks, followed by even smaller setups for individual trials.  Corresponding cleanups or tear-downs may need to happen in reverse order.

This behavior is well modeled by a depth-first traversal of a tree.  Thus, tops defines the "topsBlockTree" to organize setup, execution, and tear-down of experiments, tasks, trials, etc.

### LOOPING ###
During a trial, many concurrent behaviors may need to happen in a time-sensitive way.  These might include checking for user input, updating some model of behavior, computing new graphics frame, and sending the frame to the graphics card for display.

A program loop can manage such concurrent behavior.  tops defines the "topsFunctionLoop" which lets you collect various functions to be called in loop-fashion.  topsFunctionLoop also lets you organize multiple loop "modes" which can be sorted, combined, and executed conveniently.

### MODES OF OPERATION ###
An experimenter should be able to do all the setup for an experiment once, at the beginning, and then run various tasks and trials in whatever order.

tops defines the "topsModalList" which can hold program variables and objects and group them into various "modes" which can be accessed separately for a given task, trial, etc.

### LOGGING DATA ###
An experimenter should be able to look back at an experiment and know what happened, when.  They should be able to record as much what/when information as they need, without worrying about things like memory allocation.  In addition, experiment software should automatically log basic what/when information without the experimenter having to ask for it--the experimenter shouldn't have to anticipate every conceivable event of interest.

Thus, tops defines the "topsDataLog" which makes it easy to log data, along with time-stamps and mnemonics.  Other tops classes automatically add to the data log as they do their own work.

### GRAPHICAL INTERFACES ###
Most experimenters are not experienced programmers.  They may not be adept at managing complicated programs.  They may waste time by misunderstanding what a program is doing or what they're really asking a program to do.

Thus, tops attempts to make program behavior transparent and intuitive with built-in graphical interfaces each of its "foundation" classes.  The first job of each GUI is to keep its appearance in sync with the data and actions of its associated foundation object--it should give users a view under the hood.  In cases where it really makes sense, a GUI might also let a user initiate or interrupt foundataion class behavior.

(not done, only topsDataLogGUI exists...)


# tops big ideas #
It's probably worth identifying some guiding principles.

### WORTH USING ###
The main goal of tops is to be worth a user's time.  If tops asks a user to design an experiment using particular concepts (trees, loops) it should repay that effort with well-behaving classes, transparent GUIs, and pre-invented wheels.  If this is not the case, tops or its documentation are probaby wrong!

### INDEPENDENCE AND INTEGRATION ###
tops should depend only on Matlab.  A user should be able to use all of the features of tops without installing any other application or library.

An example is timekeeping.  The default timekeeping function for tops classes is Matlab's built-in @now function.  @now may be inconvenient because it keeps time in days, not seconds, or inadequate for high-precision timekeeping.  But it is the highest-precision, standalone clock function that Matlab provides.

However, tops should easily integrate with other libraries.  For example, Psychtoolbox users can easily substitute @GetSecs for @now, and enjoy all the benefits of that stable, high-precision timing.  Other users might even use a simple "clock" that just counts trials.

### SMALL TASKS ###
tops should encourage a myopic design habit.  That is, users should be able to design narrowly-purposed functions and classes (e.g. draw this stimulus, check this input) and let tops integrate them into grander behavior.

tops itself should be hyperopic.  It should provide over-arching structure and leave the details of an experiment up to the experimenter.

### MODES AND MNEMONICS ###
tops frequently uses the concepts of mode and mnemonic to organize things.  These are similar concepts--they are both user-defined labels stored as strings--but they are different:
> -A mode describes a particular group of values (e.g. data from the "reaction time task") or a particular group of operations (e.g. functions for running the "reaction time trial").
> -A menmonic should be more like a tag put on a single value (e.g. "reaction time") or object (e.g. "fixation point").

### OBJECT-ORIENTED ###
tops uses an object-oriented approach to most programming tasks.

### TESTABILITY ###
Each of the tops classes and functions should be unit-testable.  That is, tops should use a testing framework (to be determined...m-unit?) that can put each  the tops classe through its paces and check that it's behaving reasonably and not crashing.  This shoould facilite development, installation, and collaboration.

tops should also run itself though integration tests.  This might look like a phoney experiment that makes use of all of the tops foundation classes.  It should run without supervision or even a real subject.  It should not crash, and it should produce a reasonable-looking data log.

Integration tests should be extensible so that tops can also test itself against other libraries (like Psychtolbox) and custom code.

# tops Matlab concepts #
tops is written in Matlab and should take advantage of what Matlab has to offer.  It relies on a few Matlab concepts, in particular.

### "FEVALABLES" ###
One of the major currencies of tops is the _fevalable_ cell array.  This is a cell array whose first element is a function handle and whose other elements are arguments to pass to that function.  For example the Matlab code,
```
foo = {@disp, 'abracadabra'};
```
defines a _fevalable_ cell array called "foo" which, when executed, will display "abracadabra" in the Matlab command window.

_Fevalable_ cell arrays must work with Matlab's @feval function.  Thus, foo is a _fevalable_ cell array only if it's possible to execute the code
```
feval(foo{:});
```

It may be worth noting that the _fevalable_ cell array is not a new data type.  It's just a way of using Matlab's cell arrays and function handles to package up a function with some data.  Since this usage is common throughout tops, it's useful to give it the name "fevalable".

### FEVALABLES vs. ANONYMOUS FUNCTIONS ###
Matlab also defines the anonymous function, which is another way of packaging a function with some data.  In many cases an fevalable and an anonymous function can produce the same behavior.  Consider the following two examples, which are equivalent:
```
% fevalable
foo = {@disp, 'abracadabra'};
feval(foo{:});

% anonymous function
foo = @() disp('abracadabra');
feval(foo);
```
tops uses both, but favors fevalables because they have a more intuitive appearance and because each element of an fevalable can be accessed and manipulated programmatically.  fevalables also seem to enjoy shorter, more consistent execution times in some cases.

### PORTABLE SUBFUNCTIONS ###
A good way to define focused behaviors is by breaking a task into multiple smaller tasks.  Matlab lets you do this by defining a main function and multiple subfunctions withing the same m-file.

You can package up subfunctions as fevalables and return them from your main function.  You can then pass the fevalable from file to file, or object to object, just like any other variable, and it will remain valid and usable.  It's portable!

### "HANDLE" OBJECTS, REFERENCES ###
As of Matlab 2008a, Matlab supports object-oriented programming and passing of objects by reference (so-called "handles").  Thus, many objects in tops are subclasses of the Matlab "handle" class.  This means that different functions can access the self-same object and modify it concurrently.

References should be familiar to programmers, but may be new to users who are used to Matlab's usual copying behavior.  Most Matlab variables are copied, not referenced, so that one function cannot access or modify a variable in used by another function.

2009 benjamin.heasly@gmail.com, Seattle, WA