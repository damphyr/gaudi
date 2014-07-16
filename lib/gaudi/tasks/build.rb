namespace :build do
  desc "Builds the deployment specified with DEPLOYMENT.\n rake build:deployment DEPLOYMENT=Foo"
  task :deployment do
    include Gaudi::Tasks::Build
    deployment=Gaudi::Deployment.new($configuration.deployment,$configuration)
    t=deployment_task(deployment,$configuration)
    Rake::Task[t].invoke
  end
end