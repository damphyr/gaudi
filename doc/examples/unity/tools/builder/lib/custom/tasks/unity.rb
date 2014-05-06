namespace :test do
  desc "Builds and runs the unit tests for COMPONENT"
  task :unit do
    include UnityOperations
    component=Gaudi::Component.new($configuration.component,$configuration)
    t=unity_task(component,$configuration)
    Rake::Task[t].invoke
  end
end