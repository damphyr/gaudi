#I, Developer!

##Add a new Deployment

 * Create a subdirectory in src/deployments with the name of the deployment.
 * Add a subdirectory for each platform the Deployment provides executables for.
 * Create a program configuration file for each program

```ruby
prefix=Dummy
#the comma separated list of code components used in this executable
deps=Foo,Bar
```

Build it with 
```bash
rake build:deployment DEPLOYMENT=Dummy
```

##Add a new code component

Create a subdirectory in the source directory using the standard Gaudi structure:
```
Foo/
    |-inc #Include files usable outside the component
    |-test #Tests for this code component
    |-*.* #All othe files (sources and build.cfg)
```
Create a file build.cfg in the code component directory:

```ruby
prefix=Foo
#a comma separated list of the code components Foo depends on
deps=Bar
```

##Add extra compiler options to a code component

Some times we want to compile a component with additional compiler flags. The extra options can be added in the build.cfg file of the code component.

```ruby
prefix=Foo
deps=Bar
compiler_options= -DFOO
assembler_options= -whatever
```

##Use a code component as a shared library

Compiling a code component as a shared library is platform specific and might require extra compiler flags.
For example compiling a shared library with gcc needs the -fpic parameter. This is done in the code component's build.cfg (see previous section).

Additionally, you need to specify that the component is used as a shared library in the program configuration:

```ruby
prefix=FooProgram
#This will statically link the contents of Bar 
deps=Bar
#This will build component Foo as a shared library
shared_deps= Foo
```
