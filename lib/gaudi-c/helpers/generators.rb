require 'rake/dsl_definition'
require_relative 'operations'

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
        deps=system_config.configuration_files
        deps+=component.configuration.configuration_files
        deps+=component.headers
        ###TODO: here any change in a dependency's interface header will trigger a build which slows incremental builds down.
        #The solution is to parse the code and add the dependencies per file
        #this is one more file task chain (obj->headers_info->c). Zukunftsmusik!
        component.dependencies.each{|dep| deps+=dep.interface }
        return deps.uniq
      end
      #Returns the general dependencies for an object file task
      def object_task_dependencies src,component,system_config
        [src]+component_task_dependencies(component,system_config)
      end
    end

    #Tasks::Build contains all task generation methods for building source code
    #
    #When building a deployment the chain of task dependencies looks like:
    # deployment => programs => linker command files => objects => compiler command files => sources
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
        deps+=system_config.configuration_files
        task deployment.name => deps
      end
      #Returns a task for building a Program
      def program_task program,system_config
        deps=component_task_dependencies(program,system_config)
        Gaudi::Configuration::PlatformConfiguration.extend(program,system_config) do
          deps+=program.sources.map{|src| object_task(src,program,system_config)}
          program.dependencies.each do |dep|
            Gaudi::Configuration::PlatformConfiguration.extend(dep,system_config) do
              deps+=dep.sources.map{|src| object_task(src,dep,system_config)}
            end
          end
          program.shared_dependencies.each do |dep|
            deps<<library_task(dep,system_config)
          end
          deps+=resource_tasks(program,system_config)
          deps.uniq!
          options= linker_options(program,system_config)
          cmd_file=command_file(executable(program,system_config),system_config,program.platform)
          write_file(cmd_file,options.join("\n"))
        end
        file executable(program,system_config) => deps
      end
      #Returns a task for building a library
      def library_task component,system_config
        deps=component_task_dependencies(component,system_config)
        Gaudi::Configuration::PlatformConfiguration.extend(component,system_config) do
          deps+=component.sources.map{|src| object_task(src,component,system_config)}
          options= librarian_options(component,system_config)
          cmd_file=command_file(library(component,system_config),system_config,component.platform)
          write_file(cmd_file,options.join("\n"))
        end
        file library(component,system_config) => deps
      end
      #Returns the task to create an object file from src
      def object_task src,component,system_config
        options=[]
        if is_source?(src)
          if is_assembly?(src)
            options= assembler_options(src,component,system_config)
          else
            options= compiler_options(src,component,system_config)
          end
        end
        t=object_file(src,component,system_config)
        cmd_file=command_file(t,system_config,component.platform)
        write_file(cmd_file,options.join("\n"))
        file t => object_task_dependencies(src,component,system_config)
      end
      #:nodoc:
      def commandfile_task cmd_file,options,dependencies
        file cmd_file => dependencies do |t|
          puts "Writing #{t.name}"
          write_file(t.name,options.join("\n"))
        end
      end
      #A list of file tasks that copy resources to the component's build output directory.
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

  module Rules
    module Build
      #Creates all rake rules for the given platform
      def all_rules system_config
        system_config.platforms.each do |platform|
          executable_rule(system_config,platform)
          object_rule(system_config,platform)
        end
      end
      #Creates a rake rule for executables files of the given platform
      def executable_rule system_config,platform
        platform_config=system_config.platform_config(platform)
        _,_,exe=platform_config.extensions
        #we configure them with dots which messes the regexp up
        ext=exe.gsub(".","")
        rule(/#{platform}\/.*\.#{ext}$/) do |t|
          include Gaudi::ArtifactAdapters::Build
          build(t,system_config,platform)
        end
      end
      #Creates a rake rule for object files of the given platform
      def object_rule system_config,platform
        platform_config=system_config.platform_config(platform)
        obj,_,_=platform_config.extensions
        #we configure them with dots which messes the regexp up
        ext=obj.gsub(".","")
        rule(/#{platform}\/.*\.#{ext}$/) do |t|
          include Gaudi::ArtifactAdapters::Build
          compile(t,system_config,platform)
        end
      end
    end
  end
end
