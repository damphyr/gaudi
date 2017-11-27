# The Gaudi Coding Style

## System configuration

Gaudi exposes the system configuration in a global variable called $configuration.

We refer to $configuration **only** within tasks. No gaudi helper module or method with EVER access $configuration directly. The system configuration is always passed to the method as a parameter named system_config.

## Method parameters

Method parameters are defined from specific to generic and the last two are always system_config,platform (when the method is platform independent, then system_config is the last parameter).

```ruby
def determine_directories name,source_directories,system_config,platform
#...
end
def compile filetask,system_config,platform
#...
end
```

## Helpers & Tasks

The code is organized in modules and each task includes the modules needed

```ruby
desc "Builds the deployment specified with DEPLOYMENT.\n rake build:deployment DEPLOYMENT=Foo"
task :deployment do
  include Gaudi::Tasks::Build
  deployment=Gaudi::Deployment.new($configuration.deployment,$configuration)
  t=deployment_task(deployment,$configuration)
  Rake::Task[t].invoke
end
```

## Parametrizing tasks

Rake allows us to create tasks that accept parameters but in gaudi we chose to use environment variables.

This allows us to easily set defaults in development environment installations and has the added benefit of providing reference documentation in one place by adding accessors in Gaudi::Configuration::EnvironmentOptions (see [CONFIGURATION](CONFIGURATION.md) for details)
