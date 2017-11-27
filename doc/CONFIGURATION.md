# Gaudi Configuration

Configuration is the core feature of Gaudi. The core problem Gaudi is solving is how to get all the parameters for all the tools in one place in a sufficiently flexible format to allow for the permutations needed in a typical project<sup>1</sup>.

Core to Gaudi's development environment control approach is to have the configuration in one place in a versionable, diffable format and a consistent usage interface. The latter is provided by rake, here we will address the configuration part.

## Configuration files

Everything starts with the system configuration file. If you didn't mess with the default values (and if you are reading this, you didn't) the system configuration file is in tools/build/system.cfg

For the core gaudi functionality the configuration is very simple:

```
#the project root directory
base=../../
#the build output directory
out=../../out
```

## Configuration format

Gaudi uses a very simple configuration format (even though the underlying implementation has proven rather elaborate). Basically it's the property=value format with a few embelishments:

```bash
#setenv allows you to set environment variables to be used within rake
setenv FOO=bar
#import allows you to break up the configuration across several files and compose it
import ./extra_options.cfg
```

Property values can use earlier defined properties as variables within their value with a simple percentage syntax. Example:

```bash
# Set some properties
appname=MyApplication
version_major=1
version_minor=3
# Use already defined properties within other properties
version_string=%{appname} %{version_major}.%{version_minor}
```

This will also work when reassigning the value of an already existing property. Example

```bash
path=/bin;/usr/bin;/usr/local/bin
# prepend something to path
path=/home/myuser/bin;%{path}
```

Extending the available configuration properties is done by adding modules to Gaudi::Configuration::SystemModules (for more details check [EXTENDING](EXTENDING.md))

### Precedence order

Usage of import raises the issue of what happens when a parameter is defined in several files.

Gaudi has a simple precedence system: Last one wins.

### Environment Variables

rake allows you to define an environment variable on the command line:

```bash
rake task FOO=bar
```

Gaudi supports a set of environment variables as a way for passing options and exposes these as attributes of the system configuration

 * GAUDI_CONFIG - points to the configuration file.
 * USER - passes the user name

Adding methods to Gaudi::Configuration::EnvironmentOptions is the recommended way to expose environment variables to Gaudi. This is pure convention but results in pulling the documentation of environment options together in one rdoc page. It also allows us to have parsing, validation and sanitization of input in one place.

In some cases there are two versions of the reader method for the environment variables. The bang version (i.e. user! ) will raise a GaudiConfigurationError if the requested value is nil or the empty string. When there is only one version the current choice is to raise the exception by default. 

## System Configuration

The standard configuration parameters out-of-the-box are

 * base - the root directory of the project. Usually where the rakefile is.
 * out - the build output directory.

**All paths in the configuration can be defined absolute or relative to the configuration file.**

Defining _base_ relative to the configuration file has the added advantage of making the whole configuration portable to different branches. Generally avoid absolute paths for anything that is in your project's repository, Gaudi will expand all paths to their absolute values to avoid mixups.

<hr/>
<sup>1</sup> For given values of typical that might differ from everybody else's
