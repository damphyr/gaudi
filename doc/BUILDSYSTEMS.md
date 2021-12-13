# Builders, Systems and Management

gaudi is a code substrate supporting a very specific approach to building
software systems.

The developers of gaudi call it a _Builder_. It is there to aid the creation of
a _Build System_.

Its developers also make a point in distinguishing between _Build Systems_ and
_Build **Management** Systems_:

A **build system** performs transformations in sequence according to a
predetermined dependency chain to create artifacts. A subset of this can be the
compilation of source files to binaries.

A **build management system** coordinates build system(s).

Expressing it in less hairy language: the _makefile_ is the build system, _make_
is the builder and [Jenkins](https://www.jenkins.io) is the build management
system.

In the case of gaudi, gaudi is the builder's tools and rake is the builder.

## One System to Build Them All

A build system meant to be created with gaudi goes far beyond the traditional
"compile and link" constructs the term "build system" usually refers to.

gaudi is meant to provide a consistent commandline interface to every task and
operation required in the development of a complex software project with the
express focus on making automated use easier.

The underlying principles for such a system are described by a set of
[aphorisms](ASPIRATIONS.md).

The areas of responsibility for such a system can be categorized with labels
like "build", "test" and "deploy" but this becomes much easier if these are
colour coded and added to a picture:

![Areas of Responsibility](/doc/images/BuildSystem.png)

How can such an omniscient system be created?

## Standing on The Shoulders of Giants

The basic principle is to try not to implement everything from scratch.

Shall [AsciiDoc](https://asciidoc.org) be used for documentation? 
The available application for the needed platform can be used and integrated
into the gaudi based buildsystem to codify its usage in the project.

The only constraint for technologies or toolchains that shall be integrated into
a gaudi based build system is that the chosen technology or toolchain offers a
commandline tool with a reasonable way of signaling errors (i.e. the program's
exit code).

A [walkthrough](WALKTHROUGH.md) on setting up and utilizing gaudi based build
system is available within this repository too.