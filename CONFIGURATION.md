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

For each platform in the _platforms_ entry there needs to be a platform_name=path/to/platform.cfg entry in the cofniguration file:

```bash
platforms=mingw,rx
mingw=./mingw.cfg
rx=./rx.cfg
```

**All paths in the configuration can be defined absolutely or relative to the configuration file.**
