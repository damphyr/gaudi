# Extending Gaudi

Which is to say, making the thing usable.

## Integrating custom code

It is **very strongly** advised to organize you gaudi based code in one or more [gaudi modules](MODULES.md) and to not add anything under lib/gaudi/.

Create a directory parallel to tools/build/lib/gaudi and follow the gaudi module structure:

lib/
  |-gaudi/
  |-module/
      |-helpers/
      |-tasks/
  |-gaudi.rb

Don't mix tasks and helpers, the load sequence ensures that all code in the helpers/ directory is available before loading any tasks.

To activate you custom code add to the sytem configuration:

```
gaudi_modules=module
```

For maximum reuse the [module concept](MODULES.md) allows us to reuse custom code from a git repo.

Also, you probably want to follow the [gaudi style](STYLE.md) so that custom code and core are consistent to the eye.

## Rakefiles

You only need one rakefile at the root of your repository (assuming a standard directory structure) and it looks like the following:

```ruby
require_relative 'tools/build/lib/gaudi'
env_setup(File.dirname(__FILE__))
require_relative 'tools/build/lib/gaudi/tasks'
```

If you use the gaudi gem to scaffold your project then the Rakefile is already there.

## Configuration

One of gaudi's core goals is to centralize configuration in a readable, diffable and versionable format. Consequently we need a way to add new parameters to the configuration files.

This is done using Ruby modules with a naming convention:

```ruby
module Gaudi::Configuration::SystemModules::MoarConfig
  def self.list_keys
    ['moar_list']
  end
  def self.path_keys
    ['moar_path']
  end
  def moar_list
    @config['moar_list']
  end
  #An accessor/reader method that will be available from the system configuration object.
  #
  #Also a conveniently central place for input validation, syntax checking, default value setting etc.
  def moar_path
    return required_path(@config['moar_path'])
  end
end
```

*path_keys* and *list_keys* are simple arrays of the parameter names that tell gaudi to handle these parameters in a special way.

When in *path_keys* then the value of the parameter is treated as a path and expanded to it's absolute value

When in *list_keys* then the value of the parameter is assumed to be a comma separated list of values and is parsed into an Array.

*required_path* is a helper method that will raise an error if the path is missing. Gaudi::Configuration::Helpers contains all methods used for valdation, convenience etc.

The methods are available as methods of the gaudi system configuration instance. So within a task you can do 

```
$configuration.moar_path
```

to access the configuration value.