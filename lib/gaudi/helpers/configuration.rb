require_relative '../version'
require_relative 'errors'
require 'pathname'
require 'yaml'
require 'delegate'

module Gaudi
  #Loads and returns the system configuration
  def self.configuration
    if ENV['GAUDI_CONFIG']
      #Load the system configuration
      ENV['GAUDI_CONFIG']=File.expand_path(ENV['GAUDI_CONFIG'])
      puts "Reading main configuration from \n\t#{ENV['GAUDI_CONFIG']}"
      system_config=Configuration::SystemConfiguration.new(ENV['GAUDI_CONFIG'])
      return system_config
    else
      raise "No configuration file (GAUDI_CONFIG is empty)"
    end
  end
  module Configuration
    #Switches the configuration for the given block
    #
    #It switches the system configuration by reading a completely different file.
    #
    #This makes for some interesting usage when you don't want to have multiple calls
    #with a different GAUDI_CONFIG parameter
    def self.switch_configuration configuration_file
      if block_given?
        current_configuration =  ENV['GAUDI_CONFIG']
        if File.expand_path(configuration_file) != File.expand_path(current_configuration)
          begin
            puts "Switching configuration to #{configuration_file}"
            $configuration=nil
            ENV['GAUDI_CONFIG'] = configuration_file
            $configuration=Gaudi::Configuration::SystemConfiguration.load([ENV['GAUDI_CONFIG']])
            yield
          ensure
            puts "Switching configuration back to #{current_configuration}"
            $configuration=nil
            ENV['GAUDI_CONFIG'] = current_configuration
            $configuration=Gaudi::Configuration::SystemConfiguration.load([ENV['GAUDI_CONFIG']])
          end
        end
      end
    end
    #Switches platform configuration replacing platform with the contents of the file
    #for the given block
    def self.switch_platform_configuration configuration_file,system_config,platform
      if block_given?
        begin
          puts "Switching platform configuration for #{platform} to #{configuration_file}"
          current_config=system_config.platform_config(platform)
          new_cfg_data=system_config.read_configuration(File.expand_path(configuration_file))
          system_config.set_platform_config(PlatformConfiguration.new(platform,new_cfg_data),platform)
          yield
        rescue
          raise
        ensure
          puts "Switching back platform configuration for #{platform}"
          system_config.set_platform_config(current_config,platform)
        end
      end
    end
    #Encapsulates the environment variables used to adjust the builder's configuration
    #
    #Is mixed in with SystemConfiguration
    module EnvironmentOptions
      #Defines the component name to work with, raises GaudiConfigurationError if not defined
      def component
        mandatory('COMPONENT')
      end
      #Defines the user name to work with, raises GaudiConfigurationError if not defined
      def user!
        mandatory('USER')
      end
      #Returns the user name to work with, raises no exception whatsoever
      def user
        return ENV['USER']
      end
      #Defines the deployment name to work with, raises GaudiConfigurationError if not defined
      def deployment
        mandatory('DEPLOYMENT')
      end
      private
      def mandatory env_var
        ENV[env_var] || raise(GaudiError, "Environment variable '#{env_var}' not defined.\nValue mandatory for the current task.")
      end
    end
    #Class to load the configuration from a key=value textfile with a few additions.
    #
    #Configuration classes derived from Loader override the Loader#keys method to specify characteristics for the keys.
    #
    #Paths are interpreted relative to the configuration file.
    #
    #In addition to the classic property format (key=value) Loader allows you to split the configuration in multiple files
    #and use import to put them together:
    # import additional.cfg
    #
    #Also use setenv to set the value of an environment variable
    #
    # setenv GAUDI=brilliant builder
    class Loader
      #Goes through a list of configuration files and returns the resulting merged configuration
      def self.load configuration_files,klass
        cfg=nil
        configuration_files.each do |cfg_file|
          if cfg
            cfg.merge(cfg_file)
          else
            cfg=klass.new(cfg_file)
          end
        end
        if cfg
          return cfg
        else
          raise GaudiConfigurationError, "No #{klass.to_s} configuration files in '#{configuration_files}'"
        end
      end

      #Returns all the configuration files processed (e.g. those read with import and the platform configuration files)
      #The main file (the one used in initialize) is always first in the collection
      attr_reader :configuration_files
      attr_reader :config
      def initialize filename
        @configuration_files=[File.expand_path(filename)]
        @config=read_configuration(File.expand_path(filename))
      end
      #Returns an Array containing two arrays.
      #
      #Override in Loader derived classes.
      #
      #The first one lists the names of all keys that correspond to list values (comma separated values, e.g. key=value1,value2,value3)
      #Loader will assign an Array of the values to the key, e.g. config[key]=[value1,value2,value3]
      #
      #The second Array is a list of keys that correspond to pathnames.
      #
      #Loader will then expand_path the value so that the key contains the absolute path.
      def keys
        return [],[]
      end
      def to_s
        "Gaudi #{Gaudi::Version::STRING} with #{configuration_files.first}"
      end
      #Merges the parameters from cfg_file into this instance
      def merge cfg_file
        begin
          cfg=read_configuration(cfg_file)
          list_keys,path_keys=*keys
          cfg.keys.each do |k|
            if @config.keys.include?(k) && list_keys.include?(k)
              @config[k]+=cfg[k]
            else
              @config[k]=cfg[k] #last one wins
            end
          end
          @configuration_files<<cfg_file
        rescue

        end
      end
      #Reads a configuration file and returns a hash with the
      #configuration as key-value pairs
      def read_configuration filename
        if File.exists?(filename)
          lines=File.readlines(filename)
          cfg_dir=File.dirname(filename)
          begin
            cfg=parse_content(lines,cfg_dir,*keys)
          rescue GaudiConfigurationError
            raise GaudiConfigurationError,"In #{filename} - #{$!.message}"
          end
        else
          raise GaudiConfigurationError,"Cannot load configuration.'#{filename}' not found"
        end
        return cfg
      end
      private
      #:stopdoc:
      def parse_content lines,cfg_dir,list_keys,path_keys
        cfg={}
        lines.each do |l|
          l.gsub!("\t","")
          l.chomp!
          #ignore if it starts with a hash
          unless l=~/^#/ || l.empty?
            if /^setenv\s+(?<envvar>.+?)\s*=\s*(?<val>.*)/ =~ l
              environment_variable(envvar,val)
            #if it starts with an import get a new config file
            elsif /^import\s+(?<path>.*)/ =~ l
              cfg.merge!(import_config(path,cfg_dir))
           elsif /^(?<key>.*?)\s*\+=\s*(?<v>.*)/ =~ l
              handle_key_append(key,v,cfg_dir,list_keys,path_keys,cfg)
            elsif /^(?<key>.*?)\s*=\s*(?<v>.*)/ =~ l
              cfg[key]=handle_key(key,v,cfg_dir,list_keys,path_keys,cfg)
            else
              raise GaudiConfigurationError,"Syntax error: '#{l}'"
            end
          end#unless
        end#lines.each
        return cfg
      end
      def required_path fname
        if fname && !fname.empty?
          if File.exists?(fname)
            return File.expand_path(fname)
          else
            raise GaudiConfigurationError, "Missing required file #{fname}"
          end
        else
          raise GaudiConfigurationError,"Empty value for required path"
        end
      end
      # Appends data to a key that is defined as list key
      def handle_key_append key,value,cfg_dir,list_keys,path_keys,cfg
        thisValue=handle_key(key,value,cfg_dir,list_keys,path_keys,cfg)
        cfg[key] = [] unless cfg.has_key?(key)
        
        begin
            cfg[key].concat(thisValue).uniq!
        rescue 
        end
      end
      #checks a key against the set of path or list keys and returns the value
      #in the format we want to have.
      #
      #This means keys in list_keys come back as an Array, keys in path_keys come back as full paths
      def handle_key key,value,cfg_dir,list_keys,path_keys,cfg
        final_value=value
        # replace %{symbol} with values from already existing config values
        final_value=final_value % Hash[cfg.map{|k,v| [k.to_sym,v]}] if final_value.include? "%{"
        
        if list_keys.include?(key) && path_keys.include?(key)
          final_value=Rake::FileList[*(value.gsub(/\s*,\s*/,',').split(',').uniq.map{|d| absolute_path(d.strip,cfg_dir)})]
        elsif list_keys.include?(key)
          #here we want to handle a comma separated list of entries
          final_value=value.gsub(/\s*,\s*/,',').split(',').uniq
        elsif path_keys.include?(key)
          final_value=absolute_path(value.strip,cfg_dir)
        end
        return final_value
      end
      def import_config path,cfg_dir
        path=absolute_path(path.strip,cfg_dir)
        raise GaudiConfigurationError,"Cannot find #{path} to import" unless File.exists?(path)
        @configuration_files<<path
        read_configuration(path)
      end
      def absolute_path path,cfg_dir
        if Pathname.new(path.gsub("\"","")).absolute?
          path
        else
          File.expand_path(File.join(cfg_dir,path.gsub("\"","")))
        end
      end
      def environment_variable(envvar,value)
        ENV[envvar]=value
      end
      
      def load_key_modules module_const
        list_keys=[]
        path_keys=[]
        configuration_modules=module_const.constants
        #include all the modules you find in the namespace
        configuration_modules.each do |mod|
          klass=module_const.const_get(mod)
          extend klass
          list_keys+=klass.list_keys
          path_keys+=klass.path_keys
        end
        return list_keys,path_keys
      end
      #:startdoc:
    end
    #The central configuration for the system
    #
    #The available functionality is extended through SystemModules modules
    class SystemConfiguration<Loader
      include EnvironmentOptions

      #I guess this is what you call a Factory Method?
      def self.load configuration_files
        super(configuration_files,self)
      end

      attr_accessor :config_base,:workspace,:timestamp
      def initialize filename
        load_gaudi_modules(File.expand_path(filename))
        super(filename)
        @config_base=File.dirname(configuration_files.first)
        raise GaudiConfigurationError, "Setting 'base' must be defined" unless base
        raise GaudiConfigurationError, "Setting 'out' must be defined" unless out
        @workspace=Dir.pwd
        @timestamp = Time.now
        load_platform_configurations
      end

      def keys
        load_key_modules(Gaudi::Configuration::SystemModules)
      end

      private
      #:stopdoc:
      def load_platform_configurations
        @config['platform_data']={}
        @config['platforms']||=[]
        platforms.each do |platform_name|
          path=@config[platform_name]
          path=File.expand_path(File.join(@config_base,path)) if !Pathname.new(path).absolute?
          pdata=read_configuration(path)
          @configuration_files<<path
          @config['platform_data'][platform_name]=PlatformConfiguration.new(platform_name,pdata)
        end
      end
      #makes sure we require the helper from any modules defined in the configuration
      #before we start reading the configuration to ensure that extension modules work correctly
      def load_gaudi_modules main_config_file
          lines=File.readlines(main_config_file)
          relevant_lines=lines.select do |ln|
            /base=/=~ln || /gaudi_modules=/=~ln
          end
          cfg=parse_content(relevant_lines,File.dirname(main_config_file),*keys)
          require_modules(cfg.fetch("gaudi_modules",[]),cfg["base"])
      end
      #Iterates over system_config.gaudi_modules and requires all helper files
      def require_modules module_list,base_directory
        module_list.each do |gm|
          mass_require(Rake::FileList["#{base_directory}/tools/build/lib/#{gm}/helpers/*.rb"])
          mass_require(Rake::FileList["#{base_directory}/tools/build/lib/#{gm}/rules/*.rb"])
        end
      end

      #:startdoc:
    end
    #Adding modules in this module allows SystemConfiguration to extend it's functionality
    #
    #Modules must implement two methods:
    #list_keys returning an Array with the keys that are comma separated lists
    #and path_keys returning an Array with the keys whose value is a file path
    #
    #Modules are guaranteed a @config Hash providing access to the configuration file contents
    module SystemModules
      #The absolute basics for configuration
      module BaseConfiguration
        include ConfigurationOperations
        #:stopdoc:
        def self.list_keys
          ['platforms','sources','gaudi_modules']
        end
        def self.path_keys
          ['base','out','sources']
        end
        #:startdoc:
        #The root path.
        #Every path in the system can be defined relative to this
        def base
          return @config["base"]
        end
        #The output directory
        def out
          return @config["out"]
        end
        #List of available platforms
        def platforms
          return @config['platforms']
        end
        #List of directories containing sources
        def sources
          @config["sources"].map{|d| File.expand_path(d)}
        end
        #A list of module names (directories) to automatically require next to core when loading Gaudi
        #
        #For backward compatibility reasons "custom" is always added to the list of modules
        def gaudi_modules
          @config["gaudi_modules"]||=[]
          @config["gaudi_modules"]<<"custom" unless @config["gaudi_modules"].include?("custom")
          return @config["gaudi_modules"]
        end
        #returns the platform configuration hash
        def platform_config platform
          return @config['platform_data'][platform]
        end
        #Sets the platform configuration hash
        #
        #The standard platform specific configuration options
        #are described in PlatformConfiguration
        def set_platform_config(platform_data,platform)
          @config['platform_data'][platform]=platform_data
        end
        #Returns the file extensions for the given platform
        def extensions platform
          if @config['platform_data'].keys.include?(platform)
            return @config['platform_data'][platform].extensions
          else
            raise GaudiConfigurationError,"Unknown platform #{platform}"
          end
        end
        #Return the auto_rules flag.
        #
        #This is false by default
        def auto_rules?
          @config.fetch("auto_rules",false)
        end

        alias_method :base_dir,:base
        alias_method :out_dir,:out
        alias_method :source_directories,:sources
      end
      #Platform configuration methods that proide more control over the raw Hash platform data
      module PlatformConfiguration
        include ConfigurationOperations
        #:stopdoc:
        def self.list_keys
          []
        end
        def self.path_keys
          []
        end
        #:startdoc:
        #Source file extensions
        def source_extensions platform
          return platform_config(platform)['source_extensions'].gsub(', ',',')
        end
        #Header file extensions
        def header_extensions platform
          return platform_config(platform)['header_extensions'].gsub(', ',',')
        end
        #A list of paths to be used as include paths when compiling
        #
        #Relative paths are interpreted relative to the main configuration file's location
        def external_includes platform
          includes=platform_config(platform).fetch('incs',"")
          return includes.split(',').map{|d| absolute_path(d.strip,config_base)}
        end
        #Returns an array with paths to the external libraries as defined in the platform configuration
        #
        #To do this it uses the PlatformConfiguration.external_lib_cfg file to replace the library tokens with path values
        #
        #If the file exists under trunk/lib the entry is the full path to the file
        #otherwise the entry from external_lib_cfg is returned as is (which works for system libraries i.e. winmm.lib, winole.lib etc.)
        def external_libraries platform
          external_lib_tokens=platform_config(platform).fetch('libs',"").split(',').map{|el| el.strip}
          return interpret_library_tokens(external_lib_tokens,external_libraries_config(platform),self.config_base)
        end
        #Returns an array with paths to the external libraries in use for unit tests as defined in the platform configuration
        #
        #To do this it uses the PlatformConfiguration.external_lib_cfg file to replace the library tokens with path values
        #
        #If the file exists under trunk/lib the entry is the full path to the file
        #otherwise the entry from external_lib_cfg is returned as is (which works for system libraries i.e. winmm.lib, libsqlite3 etc.)
        def unit_test_libraries platform
          external_lib_tokens=platform_config(platform).fetch('unit_test_libs',"").split(',').map{|el| el.strip}
          return interpret_library_tokens(external_lib_tokens,external_libraries_config(platform),self.config_base)
        end
        #Loads and returns the external libraries configuration
        #
        #The configuration is a {name=>path} hash and is used to
        #replace the library names used in the PLatform.external_libraries setting
        def external_libraries_config platform
          lib_config=platform_config(platform).fetch('lib_cfg',"")
          raise GaudiConfigurationError,"Missing lib_cfg entry for platform #{platform}" if lib_config.empty?
          external_lib_cfg=absolute_path(lib_config,config_base)
          raise GaudiConfigurationError,"No external library configuration for platform #{platform}" unless external_lib_cfg
          if File.exists?(external_lib_cfg)
            return YAML.load(File.read(external_lib_cfg))
          else
            raise GaudiConfigurationError,"Cannot find external library configuration #{external_lib_cfg} for platform #{platform}"
          end
        end
        #A list of files to be copied together with every program
        def resources platform
          return platform_config(platform).fetch('resources',"").split(',').map{|d| absolute_path(d.strip,config_base)}
        end
      end
    end
    #Adding modules in this module allows BuildConfiguration to extend it's functionality
    #
    #Modules must implement two methods:
    #list_keys returning an Array with the keys that are comma separated lists
    #and path_keys returning an Array with the keys whose value is a file path
    #
    #Modules are guaranteed a @config Hash providing access to the configuration file contents
    module BuildModules
      #Configuration directoves for simple components
      module ComponentConfiguration
        #:stopdoc:
        def self.list_keys
          ['deps','incs']
        end
        def self.path_keys
          ['incs']
        end
        #:startdoc:
        #The prefix is the name of the component
        #
        #It's called prefix for historical reasons ;)
        def prefix
          return @config.fetch('prefix',"")
        end
        #A list of prefixes that represent dependencies to the system's
        #internal components
        def dependencies
          return @config.fetch('deps',Rake::FileList.new)
        end
        #A list of paths to be used as include paths when compiling
        #
        #Relative paths are interpreted relative to the configuration file's location
        def external_includes
          return @config.fetch('incs',Rake::FileList.new)
        end

        alias_method :incs,:external_includes
        alias_method :deps,:dependencies
      end
      #Configuration directives for programs.
      #
      #For a Gaudi::Program instance these are added in addition to the ComponentConfiguration directives
      module ProgramConfiguration
        include ConfigurationOperations
        #:stopdoc:
        def self.list_keys
          ['libs','resources','shared_deps']
        end
        def self.path_keys
          ['resources']
        end
        #:startdoc:
        #A list of library files to be added when linking
        #
        #Relative paths are interpreted relative to the configuration file's location
        def external_libraries system_config,platform
          return interpret_library_tokens(@config.fetch('libs',[]),system_config.external_libraries_config(platform),system_config.config_base)
        end
        #Option key can be one of compiler_options, assembler_options, lirbary_options or linker_options
        #
        #These are added to the platform configuration options, they do NOT override them
        def option key
          return @config.fetch(key,'')
        end
        #List of paths to resource files that are copied with the program build
        def resources
          return @config.fetch('resources',[])
        end
        #A list of prefixes that represent shared dependencies to the system's
        #internal components
        def shared_dependencies
          return @config.fetch('shared_deps',Rake::FileList.new)
        end
        alias_method :libs,:external_libraries
      end
    end
    #For each set of sources we identify as a unit/component/group BuildConfiguration corresponds
    #to the configuration file that describe the dependencies to the rest of the system.
    class BuildConfiguration<Loader
      attr_writer :configuration_files,:config
      #I guess this is what you call a Factory Method?
      def self.load configuration_files
        cfg=nil
        configuration_files.each do |cfg_file|
          if cfg
            cfg.merge(cfg_file)
          else
            ld=Loader.new(cfg_file)
            raise GaudiConfigurationError, "No prefix in configuration #{cfg_file}" unless ld.config['prefix']
            cfg=BuildConfiguration.new(ld.config['prefix'])
            cfg.merge(cfg_file)
            cfg.configuration_files<<cfg_file
          end
        end
        raise GaudiConfigurationError, "No BuildConfiguration configuration files in '#{configuration_files}'" unless cfg
        return cfg
      end

      def initialize prefix
        @config={'prefix'=>prefix}
        @configuration_files=Rake::FileList.new  
        keys   
      end

      def keys
        load_key_modules(Gaudi::Configuration::BuildModules)
      end
    end

    #PlatformConfiguration encapsulates the platform specific part of Gaudi's configuration
    #
    #For more details check https://github.com/damphyr/gaudi/blob/master/doc/CONFIGURATION.md
    class PlatformConfiguration < DelegateClass(::Hash)
      #PlatformCofiguration.extend extends the platform configuration 
      #compiler_options, assembler_options, library_options and linker_options parameters
      #with the values given in the component configuration for the code given in the block
      #
      # PlatformConfiguration.extend(component,system_config) do
      #       perform build actions with extended platform options 
      # end
      def self.extend(component, system_config)
        if block_given?
          begin
            current_config=system_config.platform_config(component.platform)
            #extend the platform configuration with the component configuration settings
            new_cfg=current_config.dup
            system_config.source_extensions(component.platform).split(",").map{|ext| "compiler_options_#{ext.strip}"}+['compiler_options','assembler_options','library_options','linker_options'].each do |key|
              new_cfg[key]="#{current_config[key]} #{component.configuration.option(key)}"
            end
            system_config.set_platform_config(new_cfg,component.platform)
            yield
          rescue
            raise
          ensure
            system_config.set_platform_config(current_config,component.platform)
          end
        else
          raise GaudiError,"PlatformConfiguration.extend requires a block"
        end
      end

      attr_reader :name

      def initialize name,platform_data
        super(platform_data)
        @name=name
        __getobj__.merge!(platform_data)
        validate
      end

      def extensions 
        [__getobj__['object_extension'],__getobj__['library_extension'],__getobj__['executable_extension']]
      end
      private
      def validate
        ['source_extensions','header_extensions','object_extension','library_extension','executable_extension'].each do |key|
          raise GaudiConfigurationError, "Define #{key} for platform #{name}" unless self.keys.include?(key)
        end
        unless self.keys.include?("source_directories")
          self["source_directories"]="common,#{name}"
        end
      end
    end
  end
end
