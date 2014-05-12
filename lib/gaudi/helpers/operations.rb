module Gaudi
  #Functions that return platform dependent information
  #
  #The most basic of these is the extensions used for the various build artifacts.
  #
  #To add support for a new platform create a PlatformOperation::Name module with
  #a class method extensions that returns [object,library,executable]
  #
  #See PlatformOperations::MS or PlatformOperations::GCC for an example
  module PlatformOperations
    #Support for the Microsoft compiler
    module MS
      def self.extensions
        ['.obj','.lib','.exe']
      end
    end
    #Renesas RX toolchain support
    module RX
      #For Renesas CPUs the format that allows debugging is .abs
      #
      #Every other format can be had by transforming the .abs file 
      #with post-link steps
      def self.extensions
        ['.obj','.lib','.abs']
      end
    end
    #Support for the mingw compiler on windows
    module MINGW
      def self.extensions
        ['.obj','.lib','.exe']
      end
    end
    #GCC support
    module GCC
      #The lack of an extension for executables on *ix systems is problematic.
      #So we just define one for use in Gaudi.
      def self.extensions
        ['.o','.a','.e']
      end
    end
    #returns the extensions for the platform as [object,library,executable]
    def extensions platform
      if PlatformOperations.constants.include?(platform.upcase.to_sym)
        return PlatformOperations.const_get(platform.upcase).extensions
      else
        raise GaudiError,"Unknown platform #{platform}"
      end
    end
    #Returns true if the file given is a library for the given platform
    def is_library? filename,platform
      obj,lib,exe=*extensions(platform)
      return filename.end_with?(lib)
    end
    #Returns true if the file given is a library for the given platform
    def is_exe? filename,platform
      obj,lib,exe=*extensions(platform)
      return filename.end_with?(exe)
    end
    #Returns true if the file is a recognized source file
    #
    #Doesn't mean we can actually work with all of them
    def is_source? filename
      filename.downcase.end_with?('.c') ||
      filename.downcase.end_with?('.cc') ||
      filename.downcase.end_with?('.cpp') ||
      is_assembly?(filename)
    end

    def is_assembly? filename
      filename.downcase.end_with?('.asm') || filename.downcase.end_with?('.src') 
    end

    def is_header? filename
      filename.downcase.end_with?('.h') ||
      filename.downcase.end_with?('.hh')
    end
  end
  #Methods for creating and managing tool command lines
  module ToolOperations
    #Returns the compiler command line options merging the options from all
    #cofniguration files
    def compiler_options src,component,system_config
      config=system_config.platform_config(component.platform)
      output=object_file(src,component,system_config)
      opts= config['compiler_options'].split(' ')
      opts+= component.configuration.compiler_options
      opts+= prefixed_objects(component.include_paths,config['compiler_include'])
      opts<< "#{config['compiler_out']}\"#{output}\""
      opts<< src
    end
    #Returns the assembler command line options merging the options from all
    #cofniguration files
    def assembler_options src,component,system_config
      config=system_config.platform_config(component.platform)
      output=object_file(src,component,system_config)
      opts= config['assembler_options'].split(' ')
      opts<< "#{config['assembler_out']}\"#{output}\""
      opts+= prefixed_objects(component.include_paths,config['assembler_include'])
      opts+=prefixed_objects(component.directories,config['assembler_include'])
      opts<< src
    end
    #Returns the archiver command line options merging the options from all
    #cofniguration files
    def archiver_options component,system_config
      config=system_config.platform_config(component.platform)
      options= config['archive_options'].split(' ')
      #output file
      options<< "#{config['archive_out']}#{library(component,system_config)}"
      #add the object files
      objects=component.sources.map{|src| object_file(src,component,system_config)}
      options+=prefixed_objects(objects,config['archive_in'])
    end
    #Returns the linker command line options merging the options from all
    #cofniguration files
    def linker_options component,system_config
      config=system_config.platform_config(component.platform)
      options= config['linker_options'].split(' ')
      options<< "#{config['linker_out']}\"#{executable(component,system_config)}\""
      objects=component.sources.map{|src| object_file(src,component,system_config)}
      component.dependencies.each{|dep| objects+=dep.sources.map{|src| object_file(src,dep,system_config)}}
      options+= prefixed_objects(objects,config["linker_in"])
      options+= prefixed_objects(component.external_libraries,config["linker_lib"])
    end
    #returns the commandline for cmd as an Array
    def command_line cmd,cmdfile,prefix
      cmdline= [cmd]
      if prefix && !prefix.empty?
        cmdline<< "#{prefix}#{cmdfile}"
      else
        cmdline+= File.readlines(cmdfile).map{|l| l.strip}
      end
      cmdline
    end
    #adds a prefix to a list of filenames/objects
    def prefixed_objects objects,prefix_flag
      objects.map{|lo| "#{prefix_flag}#{lo}"}
    end
  end
  #Methods to do with configuration entries and data
  module ConfigurationOperations
    #Given a list of tokens it will look them up in the config Hash
    #and map them to 'base_dir/config[token]' if it exists or 'config[token]' if not
    def interpret_library_tokens tokens,config,base_dir
      tokens.map do |o| 
        raise GaudiConfigurationError,"Library token #{o} not found in the external libraries configuration" unless config[o]
        lib_path=File.expand_path(File.join(base_dir,config[o]))
        File.exists?(lib_path) ? lib_path : config[o]
      end
    end
  end
end