# Reasonings

While the parts of Gaudi that are published deal with building C/C++ programs, project specific applications include static code analysis, IDE project generation, documentation generation, test execution, reporting and release management and more or less every task you could automate in a software project.

Experience shows that even if you narrow down the scope (to say embedded C projects for very constrained devices) every project develops differently. The decision to avoid publishing a gem is based on this fact and a usage scenario as it developed over several years of using rake to build embedded systems.

Basically the build system is versioned within the project repository and does not need the extra versioning layer a gem provides. The speed of propagating  build system changes in a project under heavy development is much more important - a git pull should suffice. Also bundling as a gem introduces a disconnect between the version that is committed and the version that is installed in the development environment with sometimes unnerving consequences.

Having said that, you do need a plan for managing the inevitable cornucopia of gems that will be used in implementing tasks.

One of the benefits of Gaudi is that it provides you with all kinds of information about your code base. It is a simple step to add code that for example feeds code metrics to an information radiator for every build. Adding static code analysis is also very easy, as it operates on the same set of files that the [Gaudi objects](HIERARCHY.md) provide.

But consistent with the decision not to bundle Gaudi as a gem is the decision to only include in core Gaudi the compile/build abstractions that have proven themselves over several years and across several projects. Even there your mileage may vary so the [usage pattern](EXTENDING.md) for Gaudi is a manual process (rather ironic for a tool whose goal is automating stuff).

Check the [examples](examples/) section for code that adds functionality past the core compile/build stages.
