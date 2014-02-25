require 'rake/dsl_definition'
require_relative 'operations.rb'

module Gaudi
  #Task Generators are modules that create the types of tasks the build system supports
  module Tasks
    #Defines a file task with or without dependencies
    def self.define_file_task task_name,dependencies
      if dependencies && !dependencies.empty?
        file task_name => dependencies
      else
        file task_name
      end
    end
    #Methods to calculate dependencies for the various task types
    module TaskDependencies
      #Returns the general dependencies for a Component task
      def component_task_dependencies component,system_config
        ###TODO: here any change in a dependency's interface header will trigger a build which slows incremental builds down.
        #The solution is to parse the code and add the dependencies per file
        #this is one more file task chain (obj->headers_info->c). Zukunftsmusik!
        deps=Rake::FileList[component.configuration.to_path]
        ifaces=Rake::FileList.new
        component.dependencies.each{|dep| ifaces+=dep.interface }
        deps+=component.directories
        return deps.uniq
      end
      #Returns the general dependencies for an object file task
      def object_task_dependencies src,component,system_config
        file src => commandfile_task(src,component,system_config)
        files=[src]+component.headers
        incs=component.include_paths+component.directories
        component.dependencies.each do |dep| 
          files+=dep.interface
          incs+=dep.include_paths
        end
        files+incs
      end

      def commandfile_task_dependencies component,system_config
        files=component.headers
        component.dependencies.each do |dep| 
          files+=dep.interface
        end
        [component.configuration.to_path,system_config.to_path]+files
      end
    end

    #Tasks::Build contains all task generation methods for building source code
    #
    #When building a deployment the chain of task dependencies looks like:
    # deployment => programs => objects => command_files => sources
    module Build
      include StandardPaths
      include TaskDependencies
      include ToolOperations
      #Returns a task for building a Deployment
      #
      # t=deployment_task(deployment,system_config)
      # Rake::Task[t].invoke
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
      #Returns a task for building a Program
      def program_task program,system_config
        deps=component_task_dependencies(program,system_config)
        deps+=program.sources.map{|src| Tasks.define_file_task(object_file(src,program,system_config),object_task_dependencies(src,program,system_config))}
        program.dependencies.each do |dep|
          deps+=dep.sources.map{|src| Tasks.define_file_task(object_file(src,dep,system_config),object_task_dependencies(src,dep,system_config))}
        end
        deps<<commandfile_task(executable(program,system_config),program,system_config)
        deps+=resource_tasks(program,system_config)
        Tasks.define_file_task(executable(program,system_config),deps)
      end
      #Returns a task for building a library
      def library_task component,system_config
        deps=component_task_dependencies(component,system_config)
        deps+=component.sources.map{|src| Tasks.define_file_task(object_file(src,component,system_config),object_task_dependencies(src,component,system_config))}
        deps<<commandfile_task(library(component,system_config),component,system_config)
        Tasks.define_file_task(library(component,system_config),deps)
      end
      #Returns a task for creating a command file
      #
      #This method is heavily used in creating other tasks
      def commandfile_task src,component,system_config
        file command_file(src,system_config,component.platform) => commandfile_task_dependencies(component,system_config) do |t|
          options= []
          if is_source?(src)
            if is_assembly?(src)
              options= assembler_options(src,component,system_config)
            else
              options= compiler_options(src,component,system_config)
            end
          elsif is_library?(src,component.platform)
            options= archiver_options(component,system_config)
          elsif is_exe?(src,component.platform)
            options= linker_options(component,system_config)
          end
          write_file(t.name,options.join("\n"))
        end
      end
      #A list of file tasks that copy resources to the component's output directory.
      def resource_tasks component,system_config
        component.resources.map do |resource|
          tgt=File.join(File.dirname(executable(component,system_config)),resource.pathmap('%f'))
          file tgt => [resource] do |t|
            mkdir_p(File.dirname(t.name),:verbose=>false)
            cp(resource,t.name,:verbose=>false)
          end
        end
      end
    end
  end
end