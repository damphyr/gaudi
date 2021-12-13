# gaudi - A Builder [![CircleCI](https://circleci.com/gh/damphyr/gaudi/tree/main.svg?style=svg)](https://circleci.com/gh/damphyr/gaudi/tree/main) [![Coverage Status](https://coveralls.io/repos/damphyr/gaudi/badge.png)](https://coveralls.io/r/damphyr/gaudi) [![Code Climate](https://codeclimate.com/github/damphyr/gaudi.png)](https://codeclimate.com/github/damphyr/gaudi) [![doc status](http://inch-ci.org/github/damphyr/gaudi.svg?branch=master)](http://inch-ci.org/github/damphyr/gaudi)

gaudi is not a gem or a library. It is an approach for the construction of build
systems for highly complex projects that incorporate multiple technologies,
languages and toolchains.

## Goals

The main goals of gaudi are:

* Provision of a simple and centralized way for configuring a development
  environment beginning with the build process
* Codification of a set of conventions for projects targeting multiple platforms
* Formation of a basis for a consistent CLI interface between the developers and
  the development environment

The approach and utilization of gaudi are laid out in more detail in the
[documentation](doc/README.md) directory and the files contained therein.

## Getting started

This repository hosts the core gaudi code and the _gaudi-c_ module, a module for
building C/C++.

gaudi is meant to be part of a code repository from the initial commit on. To
that purpose there is a gaudi gem that simplifies the process of integrating
gaudi in a repository.

The gaudi gem can be installed through the _gem_ command:

```gem install gaudi```

Afterwards a project scaffold can be created with the following command:

```gaudi -s gaudi_project```

This command invocation will create a basic project structure and pull the
current version of gaudi from its upstream repository. The scaffold also adds
the correct files and structure to support features like the
[documentation tasks](doc/DOCUMENTATION.md)

The _gaudi-c_ module can be added to an existing gaudi build system scaffolding
by utilizing the below invocation of gaudi:

```gaudi -l gaudi-c https://github.com/damphyr/gaudi.git gaudi_project```

## Gaudi?

Well, if you know who [Gaudi](http://en.wikipedia.org/wiki/Antoni_Gaud%C3%AD) was you should concentrate on the fact that he rarely produced detailed plans of his works, instead he created models.

Gaudi was very much a builder and a craftsman. Each of his buildings is unique
yet based on his knowledge of the materials and the techniques for working with
them.

## LICENSE

(The MIT License)

Copyright (c) 2013-2021 Vassilis Rizopoulos

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
