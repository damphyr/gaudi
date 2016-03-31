require_relative '../../gaudi/helpers/operations'
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
    #Determine which directories correspond to the given name
    #
    #This method maps the repository directory structure to the component names
    def determine_directories name,source_directories,system_config,platform
      paths=source_directories.map{|source_dir| Rake::FileList["#{source_dir}/{#{platform},common}/#{name}"].existing}.inject(&:+)
      raise GaudiError,"Cannot find source directories for '#{name}' in #{source_directories.join(',')}" if paths.empty?
      return paths
    end
    def determine_sources component_directories,system_config,platform
      src=system_config.source_extensions(platform)
      Rake::FileList[*component_directories.pathmap("%p/**/*{#{src}}")].exclude(*determine_test_directories(component_directories).pathmap('%p/**/*'))
    end
    def determine_headers component_directories,system_config,platform
      hdr=system_config.header_extensions(platform)
      Rake::FileList[*component_directories.pathmap("%p/**/*{#{hdr}}")].exclude(*determine_test_directories(component_directories).pathmap('%p/**/*'))
    end
    def determine_test_directories component_directories
      Rake::FileList[*component_directories.pathmap('%p/test')].existing
    end
    def determine_interface_paths component_directories
      Rake::FileList[*component_directories.pathmap('%p/inc')].existing
    end
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
      src.pathmap("#{system_config.out}/#{component.platform}/#{component.parent ? component.parent.name : ''}/#{component.name}/%n#{ext_obj}")
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
  end
end