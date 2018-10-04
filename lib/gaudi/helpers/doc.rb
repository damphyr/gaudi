require 'graph'
module Gaudi
  module Documentation
    def task_graph system_config
      digraph do
        rotate
        node_attribs << filled
        task_graph_details()
        mkdir_p(File.join(system_config.out_dir,'graphs'),:verbose=>false)
        save File.join(system_config.out_dir,'graphs',"gaudi"), "png"
      end#graph
    end

    def task_graph_details
      grouped_by_namespace={}
      no_filetasks=Rake::Task.tasks.select{|rt| rt.class==Rake::Task}
      no_filetasks.each do |rt|
        name_parts=rt.name.split(":").reverse
        if name_parts.size>1
          name_space=name_parts.pop
        else
          namespace=""
        end
        grouped_by_namespace[name_space]||=[]
        grouped_by_namespace[name_space]<<rt.name
        rt.prerequisites.each{|prereq| edge rt.name,prereq}
      end
      grouped_by_namespace.each do |k,v|
        cluster k do
          v.each{|ar| node(ar)}
        end
      end
    end
  end
end
