# Gaudi Configuration

Configuration is the core feature of Gaudi. While we talk about compiling and linking and multiple platform support, the core problem Gaudi is actually solving is how to get all the parameters for all the tools in one place in a sufficiently flexible format to allow for the permutations needed in a typical project<sup>1</sup>.

Core to Gaudi's development environment control approach is to have the configuration in one place in a versionable, diffable format and a consistent usage interface. The latter is provided by rake, here we will address the configuration part.

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

### Precedence order

Usage of import raises the issue of what happens when a parameter is defined in several files.

Gaudi has a simple precedence system: Last one wins.

Environment variables can be used to pass values to Gaudi.

The 'last one wins' rule has one exception: compiler and linker options defined in program configuration files are *added* to the global compiler and linker options. The reason for this is to allow program specific settings (mostly defines) without duplicating all the options.

### Environment Variables

rake allows you to define an environment variable on the command line:

```bash
rake task FOO=bar
```

Gaudi supports a set of environment variables as a way for passing options and exposes these as attributes of the system configuration

 * GAUDI_CONFIG - points to the cofniguration file. This needs to be set, Gaudi will exit with an error if it's empty or the file does not exist
 * DEPLOYMENT - passes the deployment name 
 * COMPONENT - passes the component name
 * USER - passes the user name

Adding methods to Gaudi::Configuration::EnvironmentOptions is the recommended way to expose environment variables to Gaudi. This is pure convention but results in pulling the documentation of environment options together in one rdoc page.

In some cases there are two versions of the reader method for the environment variables. The bang version (i.e. user! ) will raise a GaudiConfigurationError if the requested value is nil or the empty string. When there is only one version the current choice is to raise the exception by default. In the case of - for example - DEPLOYMENT it rarely makes sense to work with a nil or empty value so...no bang. That is the convention, even though working with the nil returning methods is more error-prone than otherwise.

## System Configuration

The standard configuration parameters out-of-the-box are

 * base - the root directory of the project. Usually where the rakefile is.
 * out - the build output directory.
 * source - A comma separated list of directories where project sources can be found
 * platforms - a comma separated list of compiler platform names e.g. platforms= mingw,rx,qnx etc.

**All paths in the configuration can be defined absolutely or relative to the configuration file.**

Defining _base_ relative to the configuration file has the added advantage of making the whole configuration portable to different branches. Generally avoid absolute paths for anything that is in your project's repository, Gaudi will expand all paths to their absolute values to avoid mixups.

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
##### Source file setting
#all extension parameters are mandatory
source_extensions= .c,.asm #comma separated list of file extensions
header_extensions= .h #comma separated list of file extensions
object_extension= .o #single entry
library_extension= .so #single entry
executable_extension= .e #single entry
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
#### Basically the set above is repeated the linker (libraries and executables) and the assembler
#####Assembler settings
assembler= 
assembler_options= 
assembler_commandfile_prefix= 
assembler_out= 
assembler_include= 
#####Settings for linking libraries
librarian= 
library_options= 
library_in= 
library_out= 
library_commandfile_prefix= 
#####Settings for linking executables
linker= 
linker_options= 
#input files flag (some linkers do have it. You prefix every object file with it, yes you do)
linker_in= 
linker_out=
#Some linkers have a different flag for dynamically linked and statically linked libraries. Some don't
linker_lib= 
linker_commandfile_prefix= 
```

### Third party

It gets a bit more complicated. In many projects it is not uncommon to use third party libraries, which sometimes are only available in binary form. These libraries are accompanied by headers and the whole thing needs to be integrated somehow. 

So in each platform configuration you can use 

```bash
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

The incs and libs platform configuration entries will be added as compiler and linker parameters for every platform build.
<hr/>
<sup>1</sup> For given values of typical that might differ from everybody else's