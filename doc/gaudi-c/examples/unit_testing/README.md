# Unit Testing for real

Gaudi does not offer support for unit testing out of the box simply because there are so many options out there. It does foresee a place for test files in the component structure and Gaudi::Component's interface but the testing framework is left undefined.

## Unity & CMock
One of the unit testing frameworks that works really well for highly constrained embedded environments is [Unity](https://github.com/ThrowTheSwitch/Unity).

Unity is extremely lightweight, a single source file and two headers. So Unity itself can be added as a component and compiled from source every time.

Unit testing without the use of mocks is a PITA (if you're a mockist, classicists feel free to flame).

The same guys who offer [Unity](https://github.com/ThrowTheSwitch/Unity) also offer a mocking framework for C called [CMock](https://github.com/ThrowTheSwitch/CMock). As expected, CMock integrates nicely with Unity and it so happens that it's scripted parts are written in Ruby, an additional advantage when using Gaudi.

##Decisions, decisions

The bulk of the work is defining conventions, deciding were code resides and not so trivial things like "what is a unit?". Conveniently tucked under the rubrik "Conventions" this is what costs most of the time within development teams. Reaching concensus is damned difficult.

The conventions implied in this example are:
 
 * Platform is Windows and the mingw compiler
 * [Unity](src/Unity) and [CMock](src/CMock) are compiled from sourcce each time and added as components
 * We follow the directory layout defined in Gaudi::StandardPaths and as a matter of convention we add the prefix 'Test' to the source files containing the unit tests so tests for Foo will be in test/FooTest.c
 * Test runner source files have the prefix 'Runner', e.g. FooTestRunner.c is the runner for FooTest.c 
 * Mocks of "public" headers start with Mock, e.g. the mock of Foo.h is implemented in MockFoo.c and MockFoo.h 
 * Mocks are generated in the build output directory (build/mingw/mocks)

##Unit of testing

We define as the unit of testing a single component. We test the functions (these are the actual unit tests) exposed by the public headers and mock all dependencies.

This has nothing to do with Gaudi, it's just a practice to limit the amount of code you test and test some things in isolation.

## The Gaudi parts

All the code is in [custom/helpers/unit_test_c](tools/builder/custom/helpers/unit_test_c.rb)

Gaudi::Configuration::SystemModules::UnityConfiguration and Gaudi::Configuration::SystemModules::CMockConfiguration define the configuration parameters available in the Gaudi configuration and point to the scripts available from Unity and CMock.

The UnityOperations module encapsulates the code that generates test runners from the available unit test sources.
The 'test_runner_task' method creates the test runner while the 'unity_task' method creates the task to build the unit test executable.

The CMockOperations module encapsulates CMock generation with a twist: Through the 'cmock_task' method it parses the unit test code looking for include statements where the filenames start with 'Mock' and then generates the mocks automagically.

Everything comes together in the UnitTestOperations module and the 'unit_test_task' method which just integrates CMock and Unity in the correct sequence.

The [custom/tasks/unit_test_c.rb](tools/builder/custom/tasks/unit_test_c.rb) file defines the task to call on the command line

```bash
rake unit:mingw COMPONENT=Foo
```
