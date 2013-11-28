require_relative 'operations'

module Gaudi
  module Commandlines
    include ToolOperations
    #constructs the compiler command line and returns it as an Array
    def compiler cmdfile,config
      cc=config.fetch('compiler',raise(GaudiError,"Missing compiler setting"))
      return command_line(cc,cmdfile,config.fetch('compiler_commandfile_prefix',""))
    end
    #Constructs the command line for linker and returns it as an Array
    def linker cmdfile,config
      li=config.fetch('linker',raise(GaudiError,"Missing linker setting"))
      return command_line(li,cmdfile,config.fetch('linker_commandfile_prefix',""))
    end
    #constructs the assembler command line
    def assembler cmdfile,config
      as=config.fetch('assembler',raise(GaudiError,"Missing assembler setting"))
      return command_line(as,cmdfile,config.fetch('assembler_commandfile_prefix',""))
    end
    #constructs the archiver command line
    def archiver cmdfile,config
      ar=config.fetch('archiver',raise(GaudiError,"Missing archiver setting"))
      return command_line(ar,cmdfile,config.fetch('archiver_commandfile_prefix',""))
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
        cmdline
      end
      #Statically links an executable or library
      def link filename,system_config,platform
        config=system_config.platform_config(platform)
        mkdir_p(File.dirname(filename),:verbose=>false)
        if (is_library?(platform))
          cmdline = archiver(filename.pathmap('%X.archive'),config)
        else
          cmdline = linker(filename.pathmap('%X.link'),config)
        end
        cmdline
      end
    end
  end
end