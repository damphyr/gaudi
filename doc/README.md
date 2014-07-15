#Documentation

You can split the documentation for every development tool in three stages of increasing complexity.

In stage I the good developer fairy has magically created the perfect environment and all you have to do is use it.

In stage II the fairy went on holiday and now you actually have to setup and configure everything before you can actually do some work.

And in stage III you have to build the thing from scratch because the evil manager witch forces you to use it. Smile, at least it's open source <em>evil grin</em>

## Stage I : Use

  * [Object hierarchy](HIERARCHY.md) 
  * [I, Developer](DEV.md) - on the daily work with Gaudi 

## Stage II: Setup & Configure

  * Notes on [configuring Gaudi](CONFIGURATION.md)
  * [Conventions](CONVENTIONS.md)

## Stage III: No guts, no glory
 
 * [Extending](EXTENDING.md) Gaudi
 * [Examples](examples/) 

## Stage IV: Beyond the pain

 * [Reasonings](REASONINGS.md) behind the design choices in Gaudi

#Conventions

##Directory structure

In order to provide meaningful examples we have to answer the "where do I put this" question and consequently deal with filesystem structure.

Gaudi per default uses a directory structure very closely related to the open source project directory structure:

project source files are saved under src/, documentation under doc/ etc.

Additionally, third party tools are saved under tools/ and the default scaffolding task will copy the Gaudi sources under tools/build/lib.

The following image shows the structure created by the new:project scaffolding task offered by Gaudi:

![directory structure](directory_structure.png)

Following this structure any additions to the build system code should be added under tools/build/lib/custom and Gaudi will include that code automatically.

It is important that custom tasks are added as files in custom/tasks, while supporting code is added in custom/helpers. Helpers are required before any task files so that the code is available to all tasks.
