require 'rake/dsl_definition'
require_relative 'operations.rb'

#Task Generators are modules that create the types of tasks the build system supports
module Tasks
  def self.define_file_task task_name,dependencies
    if dependencies && !dependencies.empty?
      file task_name => dependencies
    else
      file task_name
    end
  end

  #Tasks::Build contains all task generation methods for building source code
  module Build
    include Filenames
    def deployment_task deployment,system_config
      deps=FileList.new
      deployment.platforms.each do |platform|
        deployment.programs(platform).each do |pgm| 
          deps<<program_task(pgm,system_config)
        end
      end
      deps<<system_config.to_path
      task deployment.name => deps
    end
    def program_task program,system_config
      ext_obj,ext_lib,ext_exe=*extensions(program.platform)
      Tasks.define_file_task(executable(program,system_config),program_task_dependencies(program,system_config))
    end
    def program_task_dependencies program,system_config
      ###TODO: this is still not granular enough, the headers are bundled all together and 
      #we cannot differentiate which source depends on which header
      deps=Rake::FileList[program.configuration]
      program.dependencies.each do |dep|
        deps+=library_task_dependencies(dep,system_config)
      end
      deps+=program.sources.map{|src| Tasks.define_file_task(object_file(src,program,system_config),[src]+program.headers)}
      return deps.uniq
    end
    def library_task_dependencies component,system_config
      ###TODO: here any change in a dependency's interface header will trigger a build which slows incremental builds down.
      #The solution is to parse the code and add the dependencies per file
      #this is one more file task chain (obj->headers_info->c). Zukunftsmusik!
      deps=Rake::FileList[component.configuration]
      ifaces=Rake::FileList.new
      component.dependencies.each{|dep| ifaces+=dep.interface }
      deps+=component.sources.map{|src| Tasks.define_file_task(object_file(src,component,system_config),[src]+component.headers+ifaces)}
      return deps.uniq
    end
  end
end