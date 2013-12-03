require_relative '../version'
require 'pathname'
require 'yaml'

module Gaudi
  def self.configuration
    #Load the system configuration
    cfg_file=File.expand_path(ENV['GAUDI_CONFIG'])
    ENV['GAUDI_CONFIG']=cfg_file
    puts "Reading main configuration from \n\t#{cfg_file}"
    system_config=SystemConfiguration.new(cfg_file)
    return system_config
  end
  module Configuration
    #Encapsulates the environment variables used to adjust the builder's configuration
    #
    #Is mixed in with SystemConfiguration
    module EnvironmentOptions
      #Defines the component name to work with, raises an exception if not defined
      def component!
        mandatory('COMPONENT')
      end
      #Defines the user name to work with, raises an exception if not define
      def user!
        mandatory('USER')
      end
      #Defines the deployment name to work with, raises an exception if not defined
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

      attr_reader :config,:config_file
      def initialize filename
        @config_file=File.expand_path(filename)
        @config=read_configuration(@config_file,*keys)
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
        "Gaudi #{Gaudi::Version::STRING} with #{@config_file}"
      end
      def to_path
        return config_file
      end
      #Merges the parameters from cfg_file into this instance
      def merge cfg_file
        begin
          cfg=read_configuration(cfg_file,*keys)
          list_keys,path_keys=*keys
          cfg.keys.each do |k|
            if @config.keys.include?(k) && list_keys.include?(k)
              @config[k]+=cfg[k]
            else
              @config[k]=cfg[k] #last one wins
            end
          end
        rescue

        end
      end
      private
      #Reads a configuration file and returns a hash with the
      #configuration as key-value pairs
      def read_configuration filename,list_keys,path_keys
        if File.exists?(filename)
          lines=File.readlines(filename)
          cfg={}
          cfg_dir=File.dirname(filename)
          
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
              elsif /^(?<key>.*?)\s*=\s*(?<v>.*)/ =~ l
                cfg[key]=handle_key(key,v,cfg_dir,list_keys,path_keys)
              else
                raise GaudiConfigurationError,"Configuration syntax error in #{filename}:\n'#{l}'"
              end
            end#unless
          end#lines.each
        else
          raise "Cannot load configuration.'#{filename}' not found"
        end
        return cfg
      end
      def required_path fname
        if fname && !fname.empty?
          if File.exists?(fname)
            return fname
          else
            raise GaudiConfigurationError, "Missing required file #{fname}"
          end
        else
          raise GaudiConfigurationError,"Empty value for required path"
        end
      end
      #checks a key against the set of path or list keys and returns the value
      #in the format we want to have.
      #
      #This means keys in list_keys come back as an Array, keys in path_keys come back as full paths
      def handle_key key,value,cfg_dir,list_keys,path_keys
        final_value=value
        if list_keys.include?(key) && path_keys.include?(key)
          final_value=Rake::FileList[*(value.gsub(/\s*,\s*/,',').split(',').uniq.map{|d| absolute_path(d,cfg_dir)})]
        elsif list_keys.include?(key)
          #here we want to handle a comma separated list of entries
          final_value=value.gsub(/\s*,\s*/,',').split(',').uniq
        elsif path_keys.include?(key)
          final_value=absolute_path(value,cfg_dir)
        end
        return final_value
      end
      def import_config path,cfg_dir
        path=absolute_path(path,cfg_dir)
        raise GaudiConfigurationError,"Cannot find #{path} to import" unless File.exists?(path)
        read_configuration(path,*keys)
      end
      def absolute_path path,cfg_dir
        if Pathname.new(path).absolute?
          path
        else
          File.expand_path(File.join(cfg_dir,path)) 
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
        super(filename)
        @config_base=File.dirname(@config_file)
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
      def load_platform_configurations
        @config['platform_data']={}
        @config['platforms']||=[]
        platforms.each do |platform|
          path=@config[platform]
          path=File.expand_path(File.join(@config_base,path)) if !Pathname.new(path).absolute?
          @config['platform_data'][platform]=read_configuration(path,*keys)
        end
      end
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
        def self.list_keys
          ['platforms','sources']
        end
        def self.path_keys
          ['base','out','sources']
        end
        #The root path. 
        #Every path in the system can be defined relative to this
        def base
          return @config["base"] 
        end
        #The output directory  
        def out
          return @config["out"]
        end
        def platforms
          return @config['platforms']
        end
        def sources
          @config["sources"].map{|d| File.expand_path(d)}
        end
        #returns the platform configuration hash
        def platform_config platform
          return @config['platform_data'][platform]
        end

        alias_method :base_dir,:base
        alias_method :out_dir,:out
        alias_method :source_directories,:sources
      end

      module Settings
        def self.list_keys
          []
        end
        def self.path_keys
          []
        end
        def default_compiler_mode
          mode=@config.fetch('default_compiler_mode','C').upcase
          valid_modes=['C','CPP']
          if valid_modes.include?(mode)
            mode
          else
            raise GaudiConfigurationError,"Theonly two acceptable values for default_compiler_mode are: [#{valid_modes.join(',')}]"
          end
        end
      end

      module PlatformConfiguration
        include ConfigurationOperations
        def self.list_keys
          []
        end
        def self.path_keys
          []
        end
        #A list of paths to be used as include paths when compiling
        #
        #Relative paths are interpreted relative to the main configuration file's location
        def external_includes platform
          includes=platform_config(platform).fetch('incs',"")
          return includes.split(',').map{|d| absolute_path(d,config_base)}
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
        #Loads and returns the external libraries configuration
        #
        #The configuration is a {name=>path} hash and is used to 
        #replace the library names used in the PLatform.external_libraries setting
        def external_libraries_config platform
          external_lib_cfg=absolute_path(platform_config(platform)['lib_cfg'],config_base)
          raise GaudiConfigurationError,"No external library configuration for platform #{platform}" unless external_lib_cfg
          if File.exists?(external_lib_cfg)
            return YAML.load(File.read(external_lib_cfg))
          else
            raise GaudiConfigurationError,"Cannot find external library configuration #{external_lib_cfg} for platform #{platform}"
          end
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
      module ComponentConfiguration
        def self.list_keys
          ['deps','incs']
        end
        def self.path_keys
          ['incs']
        end
        def prefix
          return @config['prefix']
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

        def compiler_mode(system_config)
          case (@config.fetch('compiler_mode',system_config.default_compiler_mode).upcase)
          when 'C'
            return Gaudi::CompilationUnit::C 
          when 'CPP'
            return Gaudi::CompilationUnit::CPP
          else
            raise GaudiConfigurationError,"There are only two acceptable values for compiler_mode: C or CPP"
          end
        end

        alias_method :incs,:external_includes
        alias_method :deps,:dependencies
      end

      module ProgramConfiguration
        include ConfigurationOperations
        def self.list_keys
          ['libs']
        end
        def self.path_keys
          []
        end
        #A list of library files to be added when linking
        #
        #Relative paths are interpreted relative to the configuration file's location
        def external_libraries system_config,platform
          return interpret_library_tokens(@config.fetch('libs',[]),system_config.external_libraries_config(platform),system_config.config_base)
        end

        def compiler_options
          return @config.fetch('compiler_options',[])
        end

        alias_method :libs,:external_libraries
      end
    end
    #For each set of sources we identify as a unit/component/group BuildConfiguration corresponds
    #to the configuration file that describe the dependencies to the rest of the system.
    class BuildConfiguration<Loader
      #I guess this is what you call a Factory Method?
      def self.load configuration_files
        super(configuration_files,self)
      end

      def initialize filename
        super(filename)
      end
      
      def keys
        load_key_modules(Gaudi::Configuration::BuildModules)
      end
    end
  end
end