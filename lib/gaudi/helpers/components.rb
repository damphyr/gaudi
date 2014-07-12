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
    #Returns the path to the executable file corresponding to the component
    def executable component,system_config
      ext_obj,ext_lib,ext_exe = *system_config.extensions(component.platform)
      File.join(system_config.out,component.platform,component.name,"#{component.name}#{ext_exe}")
    end
    #Returns the path to the library file corresponding to the component
    def library component,system_config
      ext_obj,ext_lib,ext_exe = *system_config.extensions(component.platform)
      File.join(system_config.out,component.platform,component.name,"#{component.name}#{ext_lib}")
    end
    #Returns the path to the object output file corresponding to src
    def object_file src,component,system_config
      ext_obj,ext_lib,ext_exe = *system_config.extensions(component.platform)
      if is_generated?(src,system_config)
        src.pathmap("%X#{ext_obj}")
      else
        src.pathmap("#{system_config.out}/#{component.platform}/#{component.name}/%n#{ext_obj}")
      end
    end
    #Returns the path to the file containing the commands for the given target
    def command_file tgt,system_config,platform
      ext="_#{platform}"
      if is_library?(tgt,system_config,platform)
        ext<<".library"
      elsif is_exe?(tgt,system_config,platform)
        ext<<".link"
      elsif is_source?(tgt)
        if is_assembly?(tgt)
          ext<<'.assemble'
        else
          ext<<'.compile'
        end
      else
        raise GaudiError,"Don't know how to name a command file for #{tgt}"
      end
      return tgt.pathmap("%X#{ext}")
    end
    #Returns the path to the unit test binary corresponding to the component
    def unit_test component,system_config
      ext_obj,ext_lib,ext_exe = *system_config.extensions(component.platform)
      File.join(system_config.out,component.platform,'tests',"#{component.name}Test#{ext_exe}")
    end
    #Is this a unit test or not?
    #
    #If you change the StandardPaths#unit_test naming convention you should 
    #implement this accordingly.
    def is_unit_test? filename
      filename.pathmap('%n').end_with?('Test')
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
    attr_reader :identifier,:platform,:configuration,:name,:directories,:test_directories
    def initialize name,system_config,platform
      @directories= determine_directories(name,system_config.source_directories,platform)
      @test_directories= determine_test_directories(@directories)
      config_files= Rake::FileList[*directories.pathmap('%p/build.cfg')].existing
      if config_files.empty? 
        raise GaudiConfigurationError,"No configuration files for #{name}" unless @configuration
      else
        @configuration = Configuration::BuildConfiguration.load(config_files)
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
      Rake::FileList[*interface_paths.pathmap("%p/**/*#{@system_config.header_extensions(platform)}")]
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
    def initialize config_file,deployment_name,system_config,platform
      configuration=Configuration::BuildConfiguration.load([config_file])
      super(configuration.prefix,system_config,platform)
      @configuration.merge(configuration)
      @deployment=deployment_name
    end
    #External (additional) libraries the Program depends on.
    def external_libraries
      @system_config.external_libraries(@platform)+@configuration.external_libraries(@system_config,platform)
    end
    #List of resources to copy with the program artifacts
    def resources
      @configuration.resources
    end
    def  shared_dependencies
      configuration.shared_dependencies.map{|dep| Component.new(dep,@system_config,platform)}
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
    def determine_directories(name,source_directories)
      Rake::FileList[*source_directories.pathmap("%p/deployments/#{name}")].existing
    end
  end
end