def graph_deployment(deployment)
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

desc "Creates a component dependency graph for DEPLOYMENT.\n rake graph:deployment DEPLOYMENT=Foo"
task :"graph:deployment" do
  require 'graph'
  deployment=Gaudi::Deployment.new($configuration.deployment,$configuration)
  digraph do
    boxes
    graph_deployment(deployment)
    mkdir_p(File.join($configuration.out_dir,'graphs'),:verbose=>false)
    save File.join($configuration.out_dir,'graphs',deployment.name), "png"
  end#graph
end