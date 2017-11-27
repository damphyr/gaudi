# Builders, Systems and Management

gaudi is the code substrate supporting a very specific approach to building software systems. 

We call it a Builder. It is there to help you create a Build System.

We also make a point in distinguishing between Build Systems and Build *Management* Systems:

A **build system** performs transformations in sequence according to a predetermined dependency chain to create artifacts. A subset of this is the compilation of sources to binaries.

A **build management system** coordinates build system(s)

Using less hairy language:  

The makefile is the build system, make is the builder and Jenkins is the build management system.

In our case, gaudi is the builder's tools and rake is the builder.

## One System to Build Them All

The build system you are meant to create with gaudi goes far beyond the traditional "compile and link" constructs we're used too.

It is meant to provide a consistent command line interface to every task and operation required in the development of your software with the express focus on making automated use easier.

The underlying principles for such a system are [described elsewhere](ASPIRATIONS.md)

The areas of responsibility for such a system can be categorized with labels like "build", "test", "deploy" but this becomes much easier if we color code it and add some pictures:

![Areas of Responsibility](images/buildSystem.png)

How do you create such an omniscient system?

## Standing on the shoulders of giants

Basically do not try to implement everything from scratch. 

Do you want to use asciidoc for documentation? 
Use the available application for your platform and use gaudi to codify its usage in your project. 

The only constraint is that the chosen technology offers a command line tool with a reasonable way of signaling errors (i.e. the program's exit code).

[And so it begins](CONFIGURATION.md)
