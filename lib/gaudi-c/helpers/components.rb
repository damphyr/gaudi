require_relative 'operations'

module Gaudi
  #This is the default directory layout:
  # src/platform
  #         |-name/     - sources and local headers
  #             |-inc/  - public headers
  #             |-test/ - unit tests
  #
  #Code can be split in several source directories and by default we will look for the files in
  #source_directory/common/name and source_directory/platform/name for every source_directory
  module StandardPaths
    include Gaudi::PlatformOperations
    #Returns the path to the file containing the commands for the given target
    def command_file tgt,system_config,platform
      ext=""
      if is_library?(tgt,system_config,platform)
        ext<<"_#{platform}.library"
      elsif is_exe?(tgt,system_config,platform)
        ext<<"_#{platform}.link"
      else
          ext<<'.breadcrumb'
      end
      return tgt.pathmap("%X#{ext}")
    end
    #Gaudi supports code generation under the convention that all generated files
    #are created in the output directory.
    def is_generated? filename,system_config
      /#{system_config.out}/=~File.expand_path(filename)
    end
  end
  #A Gaudi::Component is a logical grouping of a set of source and header files that maps to a directory structure.
  #
  #Given a base directory where sources reside, the name of Component is used to map to one or more Component source directories.
  #
  #By convention we define an inc/ directory where "public" headers reside. These headers form the interface of the Component
  #and the directory is exposed by Gaudi for use in include statements.
  class Component
    include StandardPaths
    attr_reader :identifier,:platform,:configuration,:name,:directories,:test_directories,:config_files
    #This is set to the name of the program or library containing the component when building a deployment. Default is empty
    attr_accessor :parent
    def initialize name,system_config,platform
      @parent=nil
      @directories= determine_directories(name,system_config.source_directories,system_config,platform)
      @test_directories= determine_test_directories(@directories)
      @config_files= Rake::FileList[*directories.pathmap('%p/build.cfg')].existing
      if @config_files.empty? 
        @configuration = Configuration::BuildConfiguration.new(name)
      else
        @configuration = Configuration::BuildConfiguration.load(@config_files)
      end
      @system_config= system_config
      @platform= platform
      @name=@identifier= configuration.prefix
    end
    #The components sources
    def sources
      determine_sources(directories,@system_config,@platform).uniq
    end
    #All headers
    def headers
      determine_headers(directories,@system_config,@platform).uniq
    end
    #The headers the component exposes
    def interface
      Rake::FileList[*interface_paths.pathmap("%p/**/*{#{@system_config.header_extensions(platform)}}")]
    end
    #The include paths for this Component
    def interface_paths
      determine_interface_paths(directories).uniq
    end
    #All files
    def all
      sources+headers
    end
    #All components upon which this Component depends on
    def dependencies
      configuration.dependencies.map{|dep| Component.new(dep,@system_config,platform)}
    end
    #External (additional) include paths
    def external_includes
      @system_config.external_includes(@platform)+@configuration.external_includes
    end
    #List of include paths for this component
    #
    #This should be a complete list of all paths to include so that the component compiles succesfully
    def include_paths
      incs=directories
      incs+=interface_paths
      incs+=external_includes
      dependencies.each{|dep| incs+=dep.interface_paths}
      return incs.uniq
    end
    #Test sources
    def test_files
      src=@system_config.source_extensions(platform)
      hdr=@system_config.header_extensions(platform)
      Rake::FileList[*test_directories.pathmap("%p/**/*{#{src},#{hdr}}")]
    end
  end
  #A Gaudi::Program is a collection of components built for a specific platform.
  class Program<Component
    attr_reader :deployment_name
    def initialize config_file,deployment_name,system_config,platform
      @parent=self
      @configuration=Configuration::BuildConfiguration.load([config_file])
      @name=@identifier= configuration.prefix
      @system_config= system_config
      @platform= platform
      begin
        @directories= determine_directories(@name,system_config.source_directories,system_config,platform)
      rescue GaudiError
        @directories= FileList.new
      end
      @test_directories= determine_test_directories(@directories)
      @config_files= Rake::FileList[config_file]
      @deployment_name=deployment_name
    end
    #External (additional) libraries the Program depends on.
    def external_libraries
      @system_config.external_libraries(@platform)+@configuration.external_libraries(@system_config,platform)
    end
    #List of resources to copy with the program artifacts
    def resources
      @configuration.resources
    end
    #All components upon which this Program depends on
    def dependencies
      deps=configuration.dependencies.map{|dep| program_dependency(dep)}
    end
    #All shared library components this Program depends on
    def shared_dependencies
      deps=configuration.shared_dependencies.map{|dep| program_dependency(dep)}
    end
    private
    def program_dependency dep_name
      c=Component.new(dep_name,@system_config,platform)
      c.parent=self
      return c
    end
  end
  #A Deployment is a collection of Programs compiled for multiple platforms
  #
  #It maps to a directory structure of 
  # deployment
  #    |name
  #       |platform1
  #       |platform2
  #            |program1.cfg
  #            |program2.cfg
  class Deployment
    attr_reader :name
    def initialize name,system_config
      @name=name
      @directories=determine_directories(name,system_config.source_directories)
      @system_config=system_config
      raise GaudiError,"Cannot find directories for #{name} " if @directories.empty?
      validate
    end
    #Returns the list of platforms this Deployment has programs for
    def platforms
      Rake::FileList[*@directories.pathmap("%p/*")].existing.pathmap('%n')
    end
    #A Program instance for every program configuration on the given platform
    def programs platform
      Rake::FileList[*@directories.pathmap("%p/#{platform}/*.cfg")].existing.map{|cfg| Program.new(cfg,name,@system_config,platform)}
    end
    def to_s
      name
    end
    private
    def validate
      platforms.each do |platform|
        program_names=programs(platform).map{|program| program.name}
        if program_names.uniq.size< program_names.size
          raise GaudiError,"No duplicate program names allowed on the same platform. Found duplicates on platform #{platform}"
        end
      end
    end
    def determine_directories(name,source_directories)
      Rake::FileList[*source_directories.pathmap("%p/deployments/#{name}")].existing
    end
  end
end