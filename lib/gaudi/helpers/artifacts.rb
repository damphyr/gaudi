require_relative 'operations'

module Gaudi
  module Commandlines
    include ToolOperations
    #constructs the compiler command line and returns it as an Array
    def compiler cmdfile,config
      cc=config['compiler']
      raise GaudiConfigurationError,"Missing 'compiler' setting" unless cc
      return command_line(cc,cmdfile,config.fetch('compiler_commandfile_prefix',""))
    end
    #Constructs the command line for linker and returns it as an Array
    def linker cmdfile,config
      li=config['linker']
      raise GaudiConfigurationError,"Missing 'linker' setting" unless li
      return command_line(li,cmdfile,config.fetch('linker_commandfile_prefix',""))
    end
    #constructs the assembler command line
    def assembler cmdfile,config
      as=config['assembler']
      raise GaudiConfigurationError,"Missing 'assembler' setting" unless as
      return command_line(as,cmdfile,config.fetch('assembler_commandfile_prefix',""))
    end
    #constructs the archiver command line
    def archiver cmdfile,config
      ar=config['archive']
      raise GaudiConfigurationError,"Missing 'archive' setting" unless ar
      return command_line(ar,cmdfile,config.fetch('archive_commandfile_prefix',""))
    end
  end

  module ArtifactAdapters
    module Build
      include Gaudi::Commandlines
      include Gaudi::PlatformOperations
      #Compiles a source file
      def compile src,system_config,platform
        config=system_config.platform_config(platform)
        if is_assembly?(src)
          cmdline = assembler(src.pathmap('%X.assembly'),config)
        else
          cmdline = compiler(src.pathmap('%X.compile'),config)
        end
        sh(cmdline.join(' '))
      end
      #Statically links an executable or library
      def build filename,system_config,platform
        config=system_config.platform_config(platform)
        mkdir_p(File.dirname(filename),:verbose=>false)
        if (is_library?(filename,platform))
          cmdline = archiver(filename.pathmap('%X.archive'),config)
        else
          cmdline = linker(filename.pathmap('%X.link'),config)
        end
        sh(cmdline.join(' '))
      end
    end
  end
end