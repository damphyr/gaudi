# Gaudi - A Builder [![Build Status](https://travis-ci.org/damphyr/gaudi.png)](https://travis-ci.org/damphyr/gaudi) [![Coverage Status](https://coveralls.io/repos/damphyr/gaudi/badge.png)](https://coveralls.io/r/damphyr/gaudi) [![Code Climate](https://codeclimate.com/github/damphyr/gaudi.png)](https://codeclimate.com/github/damphyr/gaudi)

tl:dr; Go to the [documentation](doc/README.md)

This is not a gem<sup>1</sup> nor is it a library. It's more like a bootstrap for creating a build system for C or C++ based projects using rake.

A couple of guidelines, a bit of supporting code, a lot of assumptions and conventions with fill-in-the-blanks space for creating a works-for-me build system.  
You're lucky I didn't call it yabsir (Yet Another Build System In Ruby)

<sup>1</sup>There is a gaudi gem. It's purpose is to help set up and maintain a Gaudi installation.

## Gaudi?

Well, if you know who [Gaudi](http://en.wikipedia.org/wiki/Antoni_Gaud%C3%AD) was you should concentrate on the fact that he rarely produced detailed plans of his works, he created models. 

Gaudi was very much a builder and a craftsman, each of his buildings unique yet based on his knowledge of the materials and the techniques for working with them.

Fat chance this code is going to be a masterpiece, but you have to aspire to something.

## Whatever for?

Well, I've done this 4 times now and some things keep getting reused and some things are improved and I have reached the point where it is easier to clone a base repository with properly tested code and fill in the blanks than actually find the previous system and remove project specific stuff.

## Will it make coffee?

Under specific circumstances, yes!

Gaudi is ostensibly a build system for component-based, multi-platform, statically linked C or C++ projects of the kind you usually get when you are creating embedded systems. In truth it's an all dancing, all singing automation tool that happens to know how to compile code.

It probably won't scale down. It's hodge-podge predecessors have been servicing teams of 7+, with projects running for longer than a year and LOC counts in the high 100Ks. Then again if you follow the default conventions it will work out of the box for any code size.

## Goals

The main goals for Gaudi are:

 * Provide a simple, centralized way for configuring a development environment beginning with the build
 * Codify a set of conventions for projects targeting multiple platforms. 
 * Form the basis for a consistent CLI interface between the developers and the development environment

Check the [documentation](doc/README.md) for more details.

## LICENSE:

(The MIT License)

Copyright (c) 2013 Vassilis Rizopoulos

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
