# gaudi Configuration

Configuration is the core feature of gaudi. The core problem gaudi is solving is
how to get all the parameters for all the tools in one place in a sufficiently
flexible format to allow for the permutations needed in a typical
project<sup>1</sup>.

Core to the development environment control approach of gaudi is to have the
configuration in one place in a versionable, diffable format and accessible
through a consistent usage interface. The latter is provided by rake. In this
file the configuration part will be addressed.

## Configuration Files

Everything starts with the system configuration file. If the default values were
not modified the system configuration file resides in `tools/build/system.cfg`
(relative to the root of the repository of the project built by gaudi).

For the core gaudi functionality the configuration is very simple:

```text
# the project root directory
base=../../
# the build output directory
out=../../out
```

## Configuration Format

gaudi uses a very simple configuration format (even though the underlying
implementation has proven to be rather elaborate). Basically it's a `property=value`
format with a few embellishments:

```bash
# setenv allows to set environment variables to be used within rake
setenv FOO=bar
# import allows to break up the configuration across several files and compose it
import ./extra_options.cfg
```

Property values can use earlier defined properties as variables within their
value with a simple percentage sign syntax. Example:

```bash
# Set some properties
appname=MyApplication
version_major=1
version_minor=3
# Use the already defined properties within other properties
version_string=%{appname} %{version_major}.%{version_minor}
```

This will also work when reassigning the value of an already existing property.
Example:

```bash
path=/bin;/usr/bin;/usr/local/bin
# Prepend something to path
path=/home/myuser/bin;%{path}
```

An extension of the available configuration properties is done by adding
respective modules to `Gaudi::Configuration::SystemModules` (for more details
check [EXTENDING](EXTENDING.md)).

### Precedence Order

The availability and usage of `import` raises the issue of what happens when a
parameter is defined in several files.

Gaudi has a simple precedence system: The last one wins.

### Environment Variables

rake allows to define environment variables on the command line:

```bash
rake task FOO=bar
```

Gaudi supports a set of environment variables as a way for passing options and
exposes these as attributes of the system configuration

* `GAUDI_CONFIG` - points to the configuration file.
* `USER` - passes the user name

Adding methods to `Gaudi::Configuration::EnvironmentOptions` is the recommended
way to expose environment variables to gaudi. This is pure convention but
results in pulling the documentation of environment options together in one RDoc
page. It also allows to have parsing, validation and sanitization of input in
one place.

In some cases there are two versions of the reader method for an environment
variable. The bang version (i.e. `user!`) will raise a `GaudiConfigurationError`
if the requested value is `nil` or an empty string. When there is only one
version the current choice is to raise the exception by default.

## System Configuration

The standard out-of-the-box configuration parameters are

* `base` - the root directory of the project. Usually where the rakefile is
* `out` - the build output directory
* `gaudi_modules` - the comma separated list of modules to require when loading
  gaudi

**All paths in the configuration can be defined absolute or relative to the
configuration file they are defined in.**

Defining `base` relative to the configuration file has the added advantage of
making the whole configuration portable to different branches. Generally
absolute paths should be avoided for anything that is within the project's
repository, gaudi will expand all paths to their absolute values to avoid
mixups.

<hr/>
<sup>1</sup> For given values of typical that might differ from everybody else's

---

Back to the [README contents](README.md)
