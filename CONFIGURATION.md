# Gaudi Configuration

Configuration is the core feature of Gaudi. While we talk about compiling and linking and multiple platform support, the core problem Gaudi is actually solving is how to get all the parameters all the tools need in one place in a sufficiantly flexible format to allow for the permutations needed in a typical project.

While the parts of Gaudi that are published deal with building C/C++ programs, project specific applications include static code analysis, IDE project generation, documentation generation, test execution, reporting and release management and more or less every task you could automate in a software project.

Core to this approach is to have the configuration in one place in a versionable, diffable format and a consistent usage interface. The latter is provided by rake, here we will address the configuration part.

## Configuration files

Essentially there are three configuration file types for Gaudi. There's the system configuration file, which IS the centralized configuration we've been talking about. Then there is the platform configuration file which serves to differentiate between the different supported compiler platforms/toolchains and at last we have the component build configuration files.

## Configuration format

Gaudi uses a very simple configuration format (even though the underlying implementation has proven rather elaborate). Basically it's the property=value format with a few embelishments:

```bash
#setenv allows you to set environment variables to be used within rake
setenv FOO=bar
#import allows you to break the file in several files and compose your configuration
import ./extra_options.cfg
```

Extending the available configuration properties is done by adding modules to Gaudi::Configuration::SystemModules (for more details check [EXTENDING](EXTENDING.md))

## System Configuration

The standard configuration parameters out-of-the-box are

 * base - the root directory of the project. Usually where the rakefile is.
 * out - the build output directory.
 * source - A comma separated list of directories where project sources can be found
 * platforms - a comma separated list of compiler platform names e.g. platforms= mingw,rx,qnx etc.
 * default_compiler_mode - an optional setting which can be C or CPP (default is C) to indicate to the system what type of compilation takes place

For each platform in the _platforms_ entry there needs to be a platform_name=path/to/platform.cfg entry in the configuration file:

```bash
platforms=mingw,rx
mingw=./mingw.cfg
rx=./rx.cfg
```

## Platform Configuration

Configuring different toolchains varies wildly so the compiler platform configuration is returned as a Hash. There is a basic set of configuration properties that are fixed at this time, but handling the configuration as a Hash allows you to arbitrarily add new properties.

A platform configuration is accessed by SystemConfiguration#platform_config(platform), where _platform_ is one of the values defined in the _platforms_ property.

```bash
######Compiler settings
#Compiler executable (gcc etc.)
compiler= 
#command line options for the compiler (-o2 etc.)
compiler_options= 
#Output flag
compiler_out=
#Command file flag (to make th compiler read a file for the parameters) 
compiler_commandfile_prefix= 
#Include path flag
compiler_include= 
#### Basically the set above is repeated for ar, the linker and the assembler
#####Assembler settings
assembler= 
assembler_options= 
assembler_commandfile_prefix= 
assembler_out= 
assembler_include= 
#####Static linker (archiver) settings
archive= 
archive_options= 
archive_in= 
archive_out= 
archive_commandfile_prefix= 
#####Dynamic linker settings
linker= 
linker_options= 
#Input files flag (some linkers do have it. You prefix ever object file with it, yes you do)
linker_in= 
linker_out=
#Some linkers have a different flag for dynamically linked and statically linked libraries. Some don't
linker_lib= 
linker_commandfile_prefix= 
```

**All paths in the configuration can be defined absolutely or relative to the configuration file.**

### Third party

It gets a bit more complicated. In many projects it is not uncommon to use third party libraries, which sometimes are only available in binary form. These libraries are acompanied by headers and the whole thing needs to be integrated somehow. 

So in each platform configuration you can use 

´´´bash
#A comma separated list of paths to use as include paths
incs= path1, always/relative/to/the/config/file, /absolute/is/also/ok
#A comma separated list of tokens
libs= foo, bar
#The yaml file matching the tokens to the actual files
lib_cfg= ./lib_cfg.yaml
```
The library configuration file is a simple YAML file:
```yaml
---
foo: lib/foo/foo.lib
bar: lib/bar/bar.lib
```

Now this might seem one layer of abstraction too much at first glance. It comes in handy if for example you use GCC and decide to use the system libraries. In that case you will set linker_lib=-l (which means linking dynamically) and then you can add 

```yaml
---
sqlite3: sqlite3
```
which will result in linking against libsqlite3.so
