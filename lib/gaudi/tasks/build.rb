namespace :build do
  desc "Builds the deployment specified with DEPLOYMENT.\n rake build:deployment DEPLOYMENT=Foo"
  task :deployment do
    include Gaudi::Tasks::Build
    deployment=Gaudi::Deployment.new($configuration.deployment,$configuration)
    t=deployment_task(deployment,$configuration)
    Rake::Task[t].invoke
  end

  desc "Builds a library for the component specified with COMPONENT.\n rake build:library COMPONENT=Foo"
  task :library do
    include Gaudi::Tasks::Build
    library=Gaudi::Component.new($configuration.component,$configuration)
    t=library_task(library,$configuration)
    Rake::Task[t].invoke
  end
end