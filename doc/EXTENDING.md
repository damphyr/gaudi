#Extending Gaudi

Which is to say, making the thing usable. As it is stated clearly in the README, Gaudi is to be used as a springboard for creating build systems and is not an off-the-shelf solution that will work out of the box. That it will work out of the box if you follow the default conventions is just a nice bonus for the three people that use those conventions.

So this document outlines where you have to replace or add stuff to get the job done.

Where defaults work and Gaudi would profit from extension we use namespaced modules:

There is a clear definition of the extension point (e.g. Gaudi::PlatformOperations) and the extension will be a module implementing an interface and following a naming convention.

There is one case where if the defaults don't work, you should replace the code and that is the Gaudi::StandardPaths module. This module encapsulates the directory structure for the sources. Consequently, if you like to arrange your files differently you will have to replace it. You will find the Gaudi::StandardPaths module in the custom/helpers/paths.rb file.

##Integrating custom code

The simplest way to get Gaudi code and your custom code together is to put them side by side in a directory. To make it even easier, Gaudi expects a custom/ directory and integrates it in it's load sequence. So you only need to drop the code in the appropriate place:

lib/
  |-gaudi/
  |-custom/
      |-helpers/
      |-tasks/
      |-rules/
  |-gaudi.rb

Don't mix tasks and helpers, the load sequence ensures that all code in the helpers/ directory is available before loading any tasks.

For maximum reuse the [module concept](MODULES.md) allows us to reuse custom code.

##Rakefiles

You only need one rakefile at the root of your repository (assuming a standard directory structure) and it looks like the following:

```ruby
require_relative 'tools/build/lib/gaudi'
env_setup(File.dirname(__FILE__))
require_relative 'tools/build/lib/gaudi/tasks'
```

If you use the gaudi gem to scaffold your project then the Rakefile is already there.

##Configuration

One of gaudi's core goals is to centralize configuration in a readable, diffable and versionable format. Cosequently we need a way to add new parameters to the configuration files.

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
  def moar_path
    return required_path(@config['moar_path'])
  end
end
```

*path_keys* and *list_keys* are simple arrays of the parameter names that tell gaudi to handle these parameters in a special way.

When in *path_keys* then the value of the parameter is treated as a path and expanded to it's absolute value

When in *list_keys* then the value of the parameter is assumed to be a comma separated list of values and is parsed into an Array.

*required_path* is a helper method that will raise an error if the path is missing.

The methods are available as methods of the gaudi system configuration instance.