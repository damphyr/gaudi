#Adding unit tests with Unity

Gaudi does not offer support for unit testing out of the box simply because there are so many options out there. It does foresee a place for test files in the component structure and Gaudi::Component's interface but the testing framework is left undefined.

##Unity
One of the unit testing frameworks that work really well for highly constrained embedded environments is [Unity]().

Unity is extremely lightweight, a single source file and two headers. So Unity itself can be added as a component and compiled from source every time.

Doing this will look like [this](src/Unity)

##Unit of testing

We define as the unit of testing a single component. We test the functions (these are the actual unit tests) exposed by the public headers and mock all dependencies.

This has nothing to do with Gaudi, it's just good practice to limit the amount of code you test and test some things in isolation.

We follow the directory layout defined in Gaudi::StandardPaths and as a matter of convention we add the prefix 'Test' to the source files containing the unit tests so tests for Foo will be in test/FooTest.c

##Building unit tests

To integrate Unity with Gaudi we [extend the system configuration](tools/build/lib/custom/helpers/unity.rb) to point the system to Unity's code generator.

To build the unit test executable we compile together Unity, the generated test runner, the tests and the component sources.

All the files are collected by the [UnityTest](tools/build/lib/custom/helpers/unity.rb) class which acts as a component and is then easily built with the standard Gaudi methods.
