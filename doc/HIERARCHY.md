#Gaudi Class Hierarchy

Gaudi has a simple view on the structure of a code base.

It consists of Deployments which contain Programs for multiple platforms. Each Program consists of multiple [Components](rdoc/Gaudi/Component.html). This makes for a very simple class hierarchy which has exactly three classes.

These classes map a project's directory structure and it's source files. 

All other functionality is within modules and in the overwhelming majority all module methods work as functions, meaning no state is actually modified. The exception to this rule is the extensions to the configuration classes and configuration switching - shameful, I know :P.

This has some interesting side-effects. You start to recognize that actions tend to apply either to Deployments (deploying via capistrano for example), Components or single files. For example linting is the same as compiling, the only thing that changes is the command line.
