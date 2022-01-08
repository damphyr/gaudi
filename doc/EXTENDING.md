# Extending gaudi

This guide describes how to add actual functionality like code generation,
compilation, deployment and so forth to a build system based on gaudi.

## Integrating custom code

It is **very strongly** advised to organize gaudi based code in one or more
[gaudi modules](MODULES.md) and to not add anything under `lib/gaudi` directly.

New modules should be created in directories parallel to `tools/build/lib/gaudi`
and follow the structure of the gaudi module:

    lib/
      |-gaudi/
          |-helpers/
          |-tasks/
      |-<gen_mod>/
          |-helpers/
          |-tasks/
      |-<build_mod>/
          |-helpers/
          |-tasks/
      |-<deploy_mod>/
          |-helpers/
          |-tasks/
      |-gaudi.rb

Helpers and tasks may not be mixed. The load sequence ensures that all code in
the `helpers/` directory is available before loading any tasks so that these can
rely on the helpers' functionality.

To activate custom modules these have to be added to the system configuration:

```text
gaudi_modules=gen_mod,build_mod,deploy_mod
```

For maximum reuse the [module concept](MODULES.md) allows to reuse custom code
from a Git repository.

Additionally new modules should follow the [gaudi style](STYLE.md) so that
custom modules' code and the gaudi core code are consistent.

## Rakefiles

At the root of the repository (assuming a standard directory structure) there
should be one central rakefile and it should look like the following:

```ruby
require_relative 'tools/build/lib/gaudi'
env_setup(File.dirname(__FILE__))
require_relative 'tools/build/lib/gaudi/tasks'
```

If the gaudi gem is used to scaffold a project, then the rakefile is already
there.

## Configuration

One of gaudi's core goals is to centralize the build system configuration in a
readable, diffable and versionable format. Consequently a way to add new
available options/parameters to the configuration files is needed.

This is realized by using Ruby modules with a naming convention:

```ruby
module Gaudi::Configuration::SystemModules::ConfigOptionsExtension
  def self.list_keys
    ['new_list_option']
  end

  def self.path_keys
    ['new_path_option']
  end

  def new_list_option
    @config['new_list_option']
  end

  # An accessor/reader method that will be available from the system
  # configuration object.
  #
  # Also a conveniently central place for input validation, syntax checking,
  # default value setting etc.
  def new_path_option
    return required_path(@config['new_path_option'])
  end
end
```

`list_keys` and `path_keys` are simple arrays of parameter names that make gaudi
handle these parameters in special ways:

* *list_keys* makes the value of the parameter being assumed to be a comma
  separated list of values and is being parsed into an Array
* *path_keys* let's the value of the parameter being treated as a path and being
  expanded to it's absolute value upon its retrieval

`required_path` is an additional helper method that will raise an error if the
passed path is missing. `Gaudi::Configuration::Helpers` is a module which
contains all methods used for validation, convenience and so forth.

The methods are available as methods of the gaudi system configuration instance.
So within a task

```ruby
$configuration.new_path_option
```

can be called to access the configuration value.
