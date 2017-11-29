desc "Creates a component dependency graph for DEPLOYMENT.\n rake graph:deployment DEPLOYMENT=Foo"
task :"graph:deployment" do
  include Gaudi::Documentation
  deployment=Gaudi::Deployment.new($configuration.deployment,$configuration)
  graph_deployment(deployment,$configuration)
end
desc "Lists all deployments"
task :"list:deployments" do 
  deployments=Rake::FileList[*$configuration.source_directories.pathmap("%p/deployments/*")].existing.pathmap("%f")
  puts "\t#{deployments.join("\n\t")}"
end