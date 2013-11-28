require_relative 'operations'

module Gaudi
  module Commandlines
    include ToolOperations
    #constructs the compiler command line and returns it as an Array
    def compiler source,output,includes,options,config
      opts= config['compiler_options'].split(' ')
      opts<< "#{config['compiler_out']}\"#{output}\""
      opts+= options
      opts+= prefixed_objects(includes,config['compiler_include'])
      opts<< source
      return command_line(config['compiler'],opts,"#{source}.compile",config['compiler_commandfile_prefix'])
    end
    
    #Constructs the command line for linker and returns it as an Array
    def linker output, objects, libraries, config
      #get the options
      options= config['linker_options'].split(' ')
      options<< "#{config['linker_out']}\"#{output}\""
      options+= prefixed_objects(objects,config["linker_in"])
      options+= prefixed_objects(libraries,config["linker_lib"])
      return command_line(config['linker'],options,"#{source}.link",config['linker_commandfile_prefix'])
    end

    #constructs the assembler command line
    def assembler source,output,includes,config
      options= config['assembler_options'].split(' ')
      options<< "#{config['assembler_out']}\"#{output}\""
      options+= prefixed_objects(includes,config['assembler_include'])
      options<< source
      return command_line(config['assembler'],options,"#{source}.assemble",config['assembler_commandfile_prefix'])
    end
    
    #constructs the archiver command line
    def archiver library,objects,config
      #get the options
      options= config['archive_options'].split(' ')
      #output file
      options<< "#{config['archive_out']}#{library}"
      #add the object files
      options+=prefixed_objects(objects,config['archive_in'])
      return command_line(config['archive'],options,"#{library}.link",config['archive_commandfile_prefix'])
    end
  end

  module ArtifactAdapters
    module Build
      include Gaudi::Commandlines
      include Gaudi::PlatformOperations
       
      #Compiles the sources and returns a list of the generated objects
      def compile sources,includes,output_directory,system_config,platform
        objects = []
        unless sources.empty?
          ext_obj,ext_ar,ext_lib,ext_exe,ext_asm = *extensions(platform)
          #create the output directory
          mkdir_p(output_directory,:verbose=>false)
          #compile each of the .c files
          sources.each do |src|
            obj = src.pathmap("#{output_directory}/%n#{ext_obj}")
            objects << obj
            #the compilation
            cmdline = compiler(src,includes,system_config,platform,obj)
            case platform
            when RX
              #change into the source directory
              Dir.chdir(src.pathmap('%d')) do
                #run the compiler
                sh( *cmdline )
              end
            else
              #system(cmdline.join(' '))
             sh( cmdline.join(' ') )            
            end
          end
        else
          $stderr.puts("No sources for #{output_directory.pathmap('%n')}")
        end
        return objects
      end
      #Compiles assembler sources and returns a list of the generated objects
      def assemble sources,includes,output_directory,system_config,platform
        ext_obj,ext_ar,ext_lib,ext_exe,ext_asm = *extensions(platform)
        unless sources.empty? 
          #create the output directory
          mkdir_p(output_directory,:verbose=>false)
          #compile each source
          sources.each do |src|
            cmdline = assembler(src,includes,output_directory,system_config,platform)
            #change into the output directory
            Dir.chdir(output_directory) do          
              sh( cmdline.join(' ') )
            end
          end
        end
        return sources.pathmap("#{output_directory}/%n#{ext_obj}")
      end
      #Statically links the link objects into a library/archive
      def static_link library,objects,system_config,platform
        output_file=library.pathmap('%f')
        unless objects.empty?
          objects.uniq!
          #the archive/lib cmdline
          cmdline=archiver(library,objects,system_config,platform)
          #create the output directory
          output_directory=library.pathmap('%d')
          mkdir_p(output_directory,:verbose=>false)
          #and link
          Dir.chdir(output_directory) do
            #delete output file because some linkers warn if it already exists
            rm_f output_file
            sh( *cmdline )
          end
        else
          $stderr.puts("No object files for #{output_file}")
        end
      end
      #Links an executable
      def exe_link exe,link_objects,system_config,platform
        output_directory=exe.pathmap('%d')
        mkdir_p(output_directory,:verbose=>false)
        #some linkers have different command line syntax for libraries and for objects
        libraries=link_objects.select{|lo| is_library?(lo,system_config,platform)}
        objects=link_objects-libraries
        raise PVTError, "Nothing to link for #{exe}" if objects.empty?
        cmdlines=linker(exe,objects,libraries,system_config,platform)
        cmdlines.each do |cmdline|
          sh( cmdline.join(' ') )
        end
      end
    end
  end
end