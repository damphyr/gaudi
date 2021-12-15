# The gaudi Coding Style

## System Configuration

gaudi exposes the system configuration in a global variable called
`$configuration`.

`$configuration` is referred to directly **only** within tasks. No gaudi helper
module or method should **ever** access `$configuration` directly. The system
configuration is always passed to helper methods that rely on it as a parameter
named `system_config`.

## Method Parameters

Method parameters are defined from specific to generic and the last two are
always `system_config` and `platform` (when the method is platform-independent,
then `system_config` is the last parameter):

```ruby
def determine_directories(name, source_directories, system_config, platform)
  #...
end

def generate(filetask, system_config)
  #...
end

def compile(filetask, system_config, platform)
  #...
end
```

## Helpers & Tasks

The code is organized in modules and each task includes the modules it requires:

```ruby
desc "Builds the deployment specified with DEPLOYMENT.\nrake build:deployment DEPLOYMENT=Foo"
task :deployment do
  include Gaudi::Tasks::Build

  deployment = Gaudi::Deployment.new($configuration.deployment, $configuration)
  t = deployment_task(deployment, $configuration)
  Rake::Task[t].invoke
end
```

## Parametrizing Tasks

Rake allows to create tasks that accept parameters but in the case of gaudi it
was chosen to use environment variables instead.

This allows to easily set defaults in development environment installations and
has the added benefit of providing reference documentation in one place by
adding accessors in `Gaudi::Configuration::EnvironmentOptions` (see
[CONFIGURATION](CONFIGURATION.md) for details).
