namespace :build do
  desc "Builds and runs the unit tests for COMPONENT"
  task :unit do
    include UnityOperations
    platform="mingw"
    component=Gaudi::Component.new($configuration.component,$configuration,platform)
    t=unity_task(component,$configuration)
    Rake::Task[t].invoke
  end
end