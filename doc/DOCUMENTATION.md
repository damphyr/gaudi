# gaudi documentation features

## Gaudi library documentation

```rake doc:gaudi```

Since rake and gaudi is Ruby code there is a built-in facility for generating RDoc documentation.

The `doc:gaudi` task will automatically generate the reference documentation for the build system code under `system_config.out/doc/gaudi`.

It uses doc/BUILDSYSTEM.md as the main page, a file that is created when using the gaudi gem to scaffold a project.

## Graphs

Gaudi is meant to cover all responsibility areas of an extended build system (as [explained elsewhere](BUILDSYSTEMS.md)).

![Areas of Responsibility](/doc/images/BuildSystem.png)

On a mature system the number of tasks can quickly become overwhelming. To manage it better gaudi provides a task to create graphs (using the [graphviz dot format](http://www.graphviz.org/doc/info/lang.html) and the [graph](https://github.com/seattlerb/graph) gem)

Use ```rake doc:graph:gaudi``` to create the diagram (as `system_config.out/doc/graphs/gaudi.png`).

One organizational measure is to group tasks by namespace. If you use the following responsibility-to-namespace mapping you will get colours in the generated graph matching the colours in the overview image.

|Area|Namespace|
|----|----|
|Generate|gen|
|Build|build|
|Static Analysis|lint|
|Unit Testing|unit|
|Package|pkg|
|Deployment|deploy|
|Test|test|

In addition the `doc` namespace is assigned the brown variant in the colour scheme

The colour pallete used is [Brewer scheme Set 1 of 9-class](http://colourbrewer2.org/#type=qualitative&scheme=Set1&n=9) 
