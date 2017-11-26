module Gaudi::Documentation
  #A simple implementation using the graph gem
  #that creates a graph of a deployment's dependencies grouped by program
  def graph_deployment(deployment,system_config)
    require 'graph'
    digraph do
      boxes
      graph_details(deployment)
      mkdir_p(File.join(system_config.out_dir,'graphs'),:verbose=>false)
      save File.join(system_config.out_dir,'graphs',deployment.name), "png"
    end#graph
  end
  private
  def graph_details deployment
    deployment.platforms.each do |platform| 
      cluster platform do
        label platform
        deployment.programs(platform).each do |program|
          cluster program.name do
            label program.name
            program.dependencies.each do |dependency|
              dependency.dependencies.each{|dep| edge "#{dependency.name}",dep.name}
            end
          end#program cluster
        end#each program
      end#platform cluster
    end#each platform
  end
end

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