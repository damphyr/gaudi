
For each platform in the _platforms_ entry there needs to be a platform_name=path/to/platform.cfg entry in the configuration file:

```bash
platforms=mingw,rx
mingw=./mingw.cfg
rx=./rx.cfg
```

## Platform Configuration

Configuring different toolchains varies wildly so the compiler platform configuration is a thin wrapper around Hash. There is a basic set of configuration properties that are fixed at this time, but handling the configuration as a Hash allows you to arbitrarily add new properties.

A platform configuration is accessed by SystemConfiguration#platform_config(platform), where _platform_ is one of the values defined in the _platforms_ property.

```bash
##### Source file setting
#all extension parameters are mandatory
source_extensions= .c,.asm #comma separated list of file extensions
header_extensions= .h #comma separated list of file extensions
object_extension= .o #single entry
library_extension= .so #single entry
executable_extension= .e #single entry
#The source subdirectories to use when combining code components
#
#By default this is common and the name of the platform
source_directories=common,foo
######Compiler settings
#Compiler executable (gcc etc.)
compiler=
#command line options for the compiler (-o2 etc.)
compiler_options=
#Output flag
compiler_out=
#Command file flag (to make the compiler read the prameters from a file)
compiler_commandfile_prefix=
#Include path flag
compiler_include=
#### Basically the set above is repeated the for the linker (libraries and executables) and the assembler
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
#Flag for dynamically linked libraries
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

Now this might seem one layer of abstraction too much at first glance. It comes in handy if for example you use GCC and decide to use the system libraries. In that case you will set linker_lib=-l and then you can add

```yaml
---
sqlite3: sqlite3
```
which will result in linking against libsqlite3.so from the system's default library paths

The incs and libs platform configuration entries will be added as compiler and linker parameters for every platform build.