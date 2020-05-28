module Gaudi
  module Documentation
    # A simple implementation using the graph gem
    # that creates a graph of a deployment's dependencies grouped by program
    def graph_deployment(deployment, system_config)
      require "graph"
      digraph do
        boxes
        graph_details(deployment)
        mkdir_p(File.join(system_config.out_dir, "graphs"), :verbose => false)
        save File.join(system_config.out_dir, "graphs", deployment.name), "png"
      end
    end

    private

    def graph_details(deployment)
      deployment.platforms.each do |platform|
        cluster platform do
          label platform
          deployment.programs(platform).each do |program|
            cluster program.name do
              label program.name
              program.dependencies.each do |dependency|
                dependency.dependencies.each { |dep| edge "#{dependency.name}", dep.name }
              end
            end
          end
        end
      end
    end
  end
end
