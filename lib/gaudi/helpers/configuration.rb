require_relative '../version'
require 'pathname'

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
              if /^setenv\s+(?<envvar>.+?)\s*=\s*(?<value>.+)/ =~ l
                environment_variable(envvar,value)
              #if it starts with an import get a new config file
              elsif /^import\s+(?<path>.*)/ =~ l
                import_config(path,cfg_dir)
              elsif /^(?<key>.*?)\s*=\s*(?<value>.*)/ =~ l
                cfg[key]=handle_key(key,value,cfg_dir,list_keys,path_keys)
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
        if list_keys.include?(key)
          #here we want to handle a comma separated list of entries
          final_value=value.gsub(/\s*,\s*/,',').split(',')
          final_value.uniq!
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
    end
    #The central configuration for the system
    #
    #The available functionality is extended through SystemModules modules
    class SystemConfiguration<Loader
      include EnvironmentOptions
      attr_accessor :config_base,:current_dir,:timestamp
      def initialize filename
        super(filename)
        @config_base=File.dirname(@config_file)
        @base_dir=@config['base_dir']
        @current_dir=Dir.pwd
        @timestamp = Time.now  
      end

      def keys
        list_keys=[]
        path_keys=[]
        configuration_modules=Gaudi::Configuration::SystemModules.constants
        #include all the modules you find in the namespace
        configuration_modules.each do |mod|
          klass=Gaudi::Configuration::SystemModules.const_get(mod)
          extend klass
          list_keys+=klass.list_keys
          path_keys+=klass.path_keys
        end
        return list_keys,path_keys
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
        def self.list_keys
            []
        end
        def self.path_keys
          ['base_dir','out_dir']
        end
        #The root path. 
        #Every path in the system can be defined relative to this
        def base_dir
           return @config["base_dir"] 
        end
        #The output directory  
        def out_dir
          return @config["out_dir"]
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
    end
  end
end