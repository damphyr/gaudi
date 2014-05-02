#Adding unit tests with Unity

Gaudi does not offer support for unit testing out of the box simply because there are so many options out there. It does foresee a place for test files in the component structure and Gaudi::Component's interface but the testing framework is left undefined.

##Unity
One of the unit testing frameworks that works really well for highly constrained embedded environments is [Unity]().

Unity is extremely lightweight, a single source file and two headers. So Unity itself can be added as a component and compiled from source every time.

Doing this will look like [this](src/Unity)

##Unit of testing

We define as the unit of testing a single component. We test the functions (these are the actual unit tests) exposed by the public headers and mock all dependencies.

This has nothing to do with Gaudi, it's just good practice to limit the amount of code you test and test some things in isolation.

We follow the directory layout defined in Gaudi::StandardPaths and as a matter of convention we add the prefix 'Test' to the source files containing the unit tests so tests for Foo will be in test/FooTest.c

##Building unit tests

In order to correctly build unit tests we need to complete the following steps:

 #. Generate the test runner
 #. Compile the component sources, unit tests, test runner and unity sources in one executable

The first step we add as a [separate task](tools/build/lib/custom/helpers/unity.rb) (the method test_runner_task). This creates a FooTestRunner.c file for the test runner that contains the main() function for the unit tests.

For the second step we let Gaudi do most of the work. The UnityTest class decorates Gaudi::Component just enough to provide the correct set of source files and include paths. The Unity sources are added as a hard-coded component dependency in the UnityTest class.

We then use the Gaudi::Tasks::Build#program_task method to create a task that will build the unit tests while respecting timestamps and doing as little work as possible in incremental builds. The unity task method makes sure the test runner is generated before attempting to build by adding it as a dependency to the program task.

All the supporting code goes in custom/helpers/unity.rb

A sample task that builds any component's unit tests s provided in [custom/tasks/unity.rb](tools/build/lib/custom/tasks/unity.rb).