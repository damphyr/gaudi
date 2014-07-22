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
    #constructs the librarian command line
    def librarian cmdfile,config
      ar=config['librarian']
      raise GaudiConfigurationError,"Missing 'librarian' setting" unless ar
      return command_line(ar,cmdfile,config.fetch('library_commandfile_prefix',""))
    end
  end

  module ArtifactAdapters
    module Build
      include Gaudi::Commandlines
      include Gaudi::PlatformOperations
      #Compiles a source file from a previously constructed command file
      def compile cmd_file,system_config,platform
        config=system_config.platform_config(platform)
        if cmd_file.end_with?('.assembly')
          cmdline = assembler(cmd_file,config)
        else
          cmdline = compiler(cmd_file,config)
        end
        sh(cmdline.join(' '))
      end
      #Links an executable or library using a previously constructed command file
      def build cmd_file,system_config,platform
        config=system_config.platform_config(platform)
        mkdir_p(File.dirname(cmd_file),:verbose=>false)
        if cmd_file.end_with?('.library')
          cmdline = librarian(cmd_file,config)
        else
          cmdline = linker(cmd_file,config)
        end
        sh(cmdline.join(' '))
      end
    end
  end
end