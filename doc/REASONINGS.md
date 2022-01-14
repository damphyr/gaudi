# Reasonings

While the parts of Gaudi that are published to deal with building C/C++
programs, project specific applications including static code analysis, IDE
project generation, documentation generation, test execution, reporting and
release management and more or less every task can be automated in a software
project.

Experience shows that even if the scope is narrowed down greatly (like so to say
in embedded C projects for very constrained devices) every project develops
differently. The decision to abstain from publishing a gaudi gem is based on
this fact and usage scenario as gaudi developed over several years of using rake
to build embedded systems.

Basically the build system is versioned within the project repository and does
not need the extra versioning layer a gem provides. The speed of propagating
build system changes in a project under heavy development is much more
important - a git pull should suffice. Also bundling as a gem introduces a
disconnect between the version that is committed and the version that is
installed in the development environment with sometimes unnerving consequences.

Having said that, a plan is needed for managing the inevitable cornucopia of
gems that will be used in implementing the tasks and their helpers.

One of the benefits of gaudi is that it provides all kinds of information about
the code base. It is a simple step to add code that for example feeds code
metrics to an information radiator for every build. Adding static code analysis
is also very easy, as it operates on the same set of files that the
[gaudi modules](MODULES.md) provide.

But consistent with the decision not to bundle gaudi as a gem is the decision to
include in core gaudi only those compilation and build abstractions that have
proven themselves over several years and across several projects. Even there the
mileage may vary so the [usage pattern](EXTENDING.md) for gaudi is a manual
process (rather ironic for a tool whose goal is to automate stuff).

The [extending gaudi](EXTENDING.md) section can be checked for code that adds
functionality past the core compilation and build stages.
