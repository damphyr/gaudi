# gaudi Walkthrough

This walkthrough presents a limited example as a demonstration of using gaudi to
integrate different tools.

A _.NET Core_ application is being used for as exemplary use case for being a
usage scenario with a very high dissonance for gaudi.

As a start the scaffolding for the project has to be created:

```bash
gaudi -s gaudi_project
```

Then a new gaudi module for the _.NET_ helpers and tasks is being created with
its own subdirectories for helpers and tasks:

```bash
mkdir -p tools/build/lib/gaudi_net/helpers
mkdir -p tools/build/lib/gaudi_net/tasks
```

This new module is then being made known to gaudi by adding it to the
`gaudi_modules` list in `tools/build/system.cfg`:

```text
gaudi_modules=gaudi_net
```

## Commandline is king

In this example a build tool shall be added to the build system. For this it is
mandatory to figure out where the tool is located and how a commandline
invocation is to be assembled.

The degree to which this can be abstracted, be organized in reusable code
modules, be validated etc. is entirely up to the individual developer. This
walkthrough is deliberately being kept really simple to illustrate the points of
integration with gaudi. In this example it is being assumed that a consistently
provisioned environment exists and that `msbuild` is being invoked with the
`dotnet msbuild` command.

The example code is organized in the usual solution/projects as customary in
_.NET_ development.

A new configuration file `tools/build/config/dotnet.cfg` with the following
content is to be created:

```text
msbuild=dotnet msbuild
msbuild_options=/nr:false /m 
msbuild_default_options=/p:StyleCopEnabled=false /p:RunCodeAnalysis=false
```

To come into effect this file has to be included into the overall build system
configuration by adding

```text
import config/msbuild.cfg
```

to `tools/build/system.cfg`.

Then a `tools/build/lib/gaudi_net/helpers/msbuild.rb` should be created with the
following content to be able to make use of the new configuration options
through the global `Gaudi::Configuration::SystemConfiguration` instance.

```ruby
##
# Configuraton options for MSBuild integration
module Gaudi::Configuration::SystemModules::MSBuild
  #:stopdoc:
  def self.list_keys
    []
  end

  def self.path_keys
    []
  end

  #:startdoc:
  ##
  # Path to the msbuild executable to use
  def msbuild
    @config['msbuild']
  end

  ##
  # Options to pass to MSBuild. Use this for things like /maxcpucount
  def msbuild_options
    @config['msbuild_options']
  end

  ##
  # Options to pass to MSBuild when compiling
  def msbuild_default_build_options
    @config['msbuild_default_build_options']
  end
end
```

The above file does not need to be restricted to creating configuration options
but is able to contain any classes, modules or methods which then can be used
either within other helpers or tasks.

The code above adds the configuration options to the global system configuration
object. A simple task can then be added by pasting the following in
`tools/build/lib/gaudi_net/tasks/build.rb`. More details on the usage of
configuration options can be found in the
[gaudi configuration documentation](CONFIGURATION.md)

```ruby
namespace :build do 
  task :hello do 
    solution = File.join($configuration.base, 'src/HelloWorld.sln')
    cmdline = "#{$configuration.msbuild} #{$configuration.msbuild_options}" \
      " #{$configuration.msbuild_default_build_options}" \
      " /p:Configuration=Relase #{solution}"
    sh(cmdline)
  end
end
```

From this point on the developer should think on how the code should be laid out
in the repository, across which modules the functionality should be split and
which configuration options, modules, classes and tasks should make up each of
them. An example of such functionality could be automatic code generation (e.g.
version metadata derived from a commit SHA). On an even higher level a possible
sharing of the code across multiple projects could be considered too.
