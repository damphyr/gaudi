# Gaudi - A Builder [![Build Status](https://travis-ci.org/damphyr/gaudi.png)](https://travis-ci.org/damphyr/gaudi) [![Coverage Status](https://coveralls.io/repos/damphyr/gaudi/badge.png)](https://coveralls.io/r/damphyr/gaudi) [![Code Climate](https://codeclimate.com/github/damphyr/gaudi.png)](https://codeclimate.com/github/damphyr/gaudi) [![doc status](http://inch-ci.org/github/damphyr/gaudi.svg?branch=master)](http://inch-ci.org/github/damphyr/gaudi)

gaudi is not a gem, or a library. It is an approach to constructing build systems for highly complex projects that incorporate multiple technologies, languages and tools.

## Goals

The main goals for Gaudi are:

 * Provide a simple, centralized way for configuring a development environment beginning with the build process
 * Codify a set of conventions for projects targeting multiple platforms.
 * Form the basis for a consistent CLI interface between the developers and the development environment

The approach is layed out in more detail in the [documentation](doc/BUILDSYSTEMS.md)

## Getting started

This repository hosts the core gaudi code and gaudi-c, the C/C++ building module.

Gaudi is meant to be a part of you code repository from the initial commit. To that purpose there is a gaudi gem that simplifies the process of integrating gaudi and repo.

Install the gaudi gem:

```gem install gaudi```

Create the project scaffold:

```gaudi -s gaudi_project```

This will create a basic project structure and pull the current version of gaudi from the repo. The scaffold also adds the correct files and structure to support features like the [documentaiton tasks](doc/DOCUMENTATION.md)

Add the gaudi-c module:

```gaudi -l gaudi-c https://github.com/damphyr/gaudi.git gaudi_project```

## Gaudi?

Well, if you know who [Gaudi](http://en.wikipedia.org/wiki/Antoni_Gaud%C3%AD) was you should concentrate on the fact that he rarely produced detailed plans of his works, he created models.

Gaudi was very much a builder and a craftsman, each of his buildings unique yet based on his knowledge of the materials and the techniques for working with them.

## LICENSE:

(The MIT License)

Copyright (c) 2013-2018 Vassilis Rizopoulos

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
