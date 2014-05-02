#Extending Gaudi

Which is to say, actually using the thing. As it is stated clearly in the README, Gaudi is to be used as a springboard for creating build systems and is not an off-the-shelf solution that will work out of the box. That it will work out of the box if you follow the default conventions is just a nice bonus for the three people that use those conventions.

So this document outlines where you have to replace or add stuff to get the job done.

Where defaults work and Gaudi would profit from extension we use namespaced modules:

There is a clear definition of the extension point (e.g. Gaudi::PlatformOperations) and the extension will be a module implementing an interface and sometimes following a naming convention.

There is one case where if the defaults don't work, you should replace the code and that is the Gaudi::StandardPaths module. This module encapsulates the directory structure for the sources. Consequently, if you like to arrange your files differently you will have to replace it.

##Integrating custom code

The simplest way to get Gaudi code and your custom code together is to put them side by side in a directory:

lib/
  |-gaudi/
  |-custom/
  |-gaudi.rb

You only need one rakefile at the root of your repository (assuming a standard directory structure. See [CONVENTIONS.md](CONVENTIONS.md) for details)

```ruby
$:.unshift('path/to/build/system/lib')
require 'gaudi'
env_setup(File.dirname(__FILE__))
#add the custom stuff here
```

##Add a platform

To add a new platform create a module in Gaudi::PlatformOperations and give it a class method 'extensions' that returns the extensions for generated files: [object,library,executable].
Make sure the name of the module is all capitals (FOO is OK, Foo is not)

```ruby
module Gaudi
  module PlatformOperations
    module FOO
      def self.extensions
        ['.obj','.lib','.exe']
      end
    end
  end
end
```