#I, Developer!

# Add a new Deployment

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

# Add a new code component

Create a subdirectory in the source directory using the standard Gaudi structure:

Foo/
    |-inc #Include files usable outside the component
    |-test #Tests for this code component
    |-*.*

Create a file build.cfg:

```ruby
prefix=Foo
#a comma separated list of the code components Foo depends on
deps=Bar
```

#Add extra compiler options to a code component

Some times we want to compile a component with additional compiler flags. The extra options can be added in the build.cfg file of the code component.

```ruby
prefix=Foo
deps=Bar
compiler_options= -DFOO
assembler_options= -whatever
```