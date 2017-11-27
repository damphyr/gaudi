# Gaudi Walkthrough

Wherein we walk through a limited example as a demonstration of using gaudi to integrate different tools.

Let us assume we have a .NET core application, since this is the usage with the highest dissonance for gaudi.

We start by scaffolding our project:

```
gaudi -s gaudi_project
```

We then add a place for our helpers and tasks:

```
mkdir -p tools/build/lib/gaudi_net/helpers
mkdir -p tools/build/lib/gaudi_net/tasks
```

and let gaudi know by editing tools/build/system.cfg and adding:

```
gaudi_modules=gaudi_net
```

# Command line is king

In this example we're adding a build tool in our build system. We need to figure out where the tool is and how to put together the command line to call it.
The degree to which this can be abstracted, organized in reusable code modules, validated etc. is entirely up to the individual developer. We're going to keep things really simple to illustrate the points of integration with gaudi.

Let us assume we have a consistently provisioned environment and we invoke msbuild with the "dotnet msbuild" command.

We also have our code organized in the usual solution/projects used in .NET

Add tools/build/config/dotnet.cfg with the following content:

```
msbuild=dotnet msbuild
msbuild_options=/nr:false /m 
msbuild_default_options=/p:StyleCopEnabled=false /p:RunCodeAnalysis=false
```

and add it to the system configuration (tools/build/system.cfg) by adding

```
import config/msbuild.cfg
```

Now add tools/build/lib/gaudi_net/helpers/msbuild.rb:

```ruby
#Configuraton options for MSBuild integration
module Gaudi::Configuration::SystemModules::MSBuild
  #:stopdoc:
  def self.list_keys
    []
  end
  def self.path_keys
    []
  end
  #:startdoc:
  #Path to the msbuild executable to use
  def msbuild
    @config['msbuild']
  end
  #Options to pass to MSBuild. Use this for things like /maxcpucount
  def msbuild_options
    @config['msbuild_options']
  end
  #Options to pass to MSBuild when compiling
  def msbuild_default_build_options
    @config['msbuild_default_build_options']
  end
end
```

The code above adds the configuration options to our system configuration object. We then add a simple task by pasting the following in tools/build/lib/gaudi_net/tasks/build.rb. For more details, look in the [configuration docs](CONFIGURATION.md)

```ruby
namespace :build do 
  task :hello do 
    solution=File.join($configuration.base,"src/HellloWorld.sln")
    cmdline="#{$configuration.msbuild} #{$configuration.msbuild_options} #{$configuration.msbuild_default_build_options} /p:Configuration=Relase #{solution}"
    sh(cmdline)
  end
end
```

At this point you should start thinking on how your code is layed out in the repository, how you want to structure your build, look into things like automatically generating assembly information (with things like version metadata that tie to the SHA of your code in the repo) and sharing it across projects etc.

