require_relative "../version"
require_relative "errors"
require_relative "environment"

require "pathname"
require "yaml"

module Gaudi
  # The path to the defualt configuration file relative to the main rakefile
  DEFAULT_CONFIGURATION_FILE = File.expand_path(File.join(File.dirname(__FILE__), "../../../system.cfg"))
  # Loads and returns the system configuration
  def self.configuration
    if ENV["GAUDI_CONFIG"]
      ENV["GAUDI_CONFIG"] = File.expand_path(ENV["GAUDI_CONFIG"])
    else
      raise "No configuration file (GAUDI_CONFIG is initially empty and #{DEFAULT_CONFIGURATION_FILE} is missing)" unless File.exist?(DEFAULT_CONFIGURATION_FILE)

      ENV["GAUDI_CONFIG"] = File.expand_path(DEFAULT_CONFIGURATION_FILE)
    end
    # Load the system configuration
    puts "Reading main configuration from \n\t#{ENV["GAUDI_CONFIG"]}"
    system_config = Configuration::SystemConfiguration.new(ENV["GAUDI_CONFIG"])
    return system_config
  end

  ##
  # Module of methods and classes for handling the parsing, extensions and
  # switching of Gaudi configuration
  module Configuration
    ##
    # Module of methods facilitating the handling of configuration entries
    module Helpers
      ##
      # Check if the file +fname+ exists and return its absolute path
      #
      # A GaudiConfigurationError is raised if +fname+ is invalid or does not
      # point to an existing file.
      def required_path(fname)
        raise GaudiConfigurationError, "Empty value for required path" unless fname && !fname.empty?

        raise GaudiConfigurationError, "Missing required file #{fname}" unless File.exist?(fname)

        return File.expand_path(fname)
      end
    end

    # Switches the configuration for the given block
    #
    # It switches the system configuration by reading a completely different file.
    #
    # This makes for some interesting usage when you don't want to have multiple calls
    # with a different GAUDI_CONFIG parameter
    def self.switch_configuration(configuration_file)
      return unless block_given?

      current_configuration = ENV["GAUDI_CONFIG"]
      return unless File.expand_path(configuration_file) != File.expand_path(current_configuration)

      begin
        puts "Switching configuration to #{configuration_file}"
        $configuration = nil
        ENV["GAUDI_CONFIG"] = configuration_file
        $configuration = Gaudi::Configuration::SystemConfiguration.load([ENV["GAUDI_CONFIG"]])
        yield
      ensure
        puts "Switching configuration back to #{current_configuration}"
        $configuration = nil
        ENV["GAUDI_CONFIG"] = current_configuration
        $configuration = Gaudi::Configuration::SystemConfiguration.load([ENV["GAUDI_CONFIG"]])
      end
    end

    # Class to load the configuration from a key=value textfile with a few additions.
    #
    # Configuration classes derived from Loader override the Loader#keys method to specify characteristics for the keys.
    #
    # Paths are interpreted relative to the configuration file.
    #
    # In addition to the classic property format (key=value) Loader allows you to split the configuration in multiple files
    # and use import to put them together:
    # import additional.cfg
    #
    # Also use setenv to set the value of an environment variable
    #
    # setenv GAUDI=brilliant builder
    class Loader
      include Helpers

      ##
      # Iterate through a list of configuration files +configuration_files+ and
      # return the resulting configuration as a new instance of class +klass+
      #
      # In case of errors upon parsing the given configurations or instantiating
      # the new +klass+ instance a GaudiConfigurationError is to be raised.
      #
      # The class +klass+ should generally be a derivative of Loader.
      def self.load(configuration_files, klass)
        cfg = nil
        configuration_files.each do |cfg_file|
          if cfg
            cfg.merge(cfg_file)
          else
            cfg = klass.new(cfg_file)
          end
        end
        raise GaudiConfigurationError, "No #{klass.to_s} configuration files in '#{configuration_files}'" unless cfg

        return cfg
      end

      # Returns all the configuration files processed (e.g. those read with import and the platform configuration files)
      # The main file (the one used in initialize) is always first in the collection
      attr_reader :configuration_files
      ##
      # A hash of the configuration files' key-value pairs
      attr_reader :config

      ##
      # Initialize a new instance by loading the configuration from +filename+
      def initialize(filename)
        @configuration_files = [File.expand_path(filename)]
        @config = read_configuration(File.expand_path(filename))
      end

      # Returns an Array containing two arrays.
      #
      # Override in Loader derived classes.
      #
      # The first one lists the names of all keys that correspond to list values (comma separated values, e.g. key=value1,value2,value3)
      # Loader will assign an Array of the values to the key, e.g. config[key]=[value1,value2,value3]
      #
      # The second Array is a list of keys that correspond to pathnames.
      #
      # Loader will then expand_path the value so that the key contains the absolute path.
      def keys
        return [], []
      end

      ##
      # Print informative string about the version of the underlying Gaudi and
      # the main configuration file
      def to_s
        "Gaudi #{Gaudi::Version::STRING} with #{configuration_files.first}"
      end

      # Merges the parameters from cfg_file into this instance
      def merge(cfg_file)
        cfg = read_configuration(cfg_file)
        list_keys, = *keys
        cfg.each_key do |k|
          if @config.keys.include?(k) && list_keys.include?(k)
            @config[k] += cfg[k]
          else
            # last one wins
            @config[k] = cfg[k]
          end
        end
        @configuration_files << cfg_file
      end

      ##
      # Read a configuration file +filename+ and returns its contents as a hash
      #
      # Returns a hash of the configuration file's interpreted contents as
      # key-value pairs
      def read_configuration(filename)
        raise GaudiConfigurationError, "Cannot load configuration.'#{filename}' not found" unless File.exist?(filename)

        lines = File.readlines(filename)
        cfg_dir = File.dirname(filename)
        begin
          cfg = parse_content(lines, cfg_dir, *keys)
        rescue GaudiConfigurationError
          raise GaudiConfigurationError, "In #{filename} - #{$!.message}"
        end

        return cfg
      end

      private

      ##
      # Parse the contents of a configuration file and return its interpreted
      # key-value combinations as a hash
      #
      # * +lines+ - the entire content of the configuration file as its
      #   individual lines
      # * +cfg_dir+ - the path of the directory the configuration file resides
      #   in
      # * +list_keys+ - a list of all keys which represent comma-separated lists
      #   of values
      # * +path_keys+ - a list of all keys representing paths
      #
      # Returns the interpreted contents of the configuration file as a hash
      def parse_content(lines, cfg_dir, list_keys, path_keys)
        cfg = {}
        lines.each do |l|
          l.gsub!("\t", "")
          l.chomp!
          # ignore if it starts with a hash
          unless l =~ /^#/ || l.empty?
            if /^setenv\s+(?<envvar>.+?)\s*=\s*(?<val>.*)/ =~ l
              environment_variable(envvar, val)
              # if it starts with an import get a new config file
            elsif /^import\s+(?<path>.*)/ =~ l
              cfg.merge!(import_config(path, cfg_dir))
            elsif /^(?<key>.*?)\s*\+=\s*(?<v>.*)/ =~ l
              handle_key_append(key, v, cfg_dir, list_keys, path_keys, cfg)
            elsif /^(?<key>.*?)\s*=\s*(?<v>.*)/ =~ l
              cfg[key] = handle_key(key, v, cfg_dir, list_keys, path_keys, cfg)
            else
              raise GaudiConfigurationError, "Syntax error: '#{l}'"
            end
          end
        end
        return cfg
      end

      ##
      # Append +value+ to a +key+ that is defined as a key representing
      # comma-separated lists
      #
      # For a detailed explanation of the arguments see #handle_key.
      #
      # Returns the combination of +value+ and potentially already existing
      # elements of +key+ as an array
      def handle_key_append(key, value, cfg_dir, list_keys, path_keys, cfg)
        this_value = handle_key(key, value, cfg_dir, list_keys, path_keys, cfg)
        cfg[key] = [] unless cfg.has_key?(key)

        begin
          cfg[key].concat(this_value).uniq!
        rescue NoMethodError
        end
      end

      ##
      # Interpret a +value+ of a certain +key+ according to further information
      #
      # * +key+ - the key of the value which is to be interpreted
      # * +value+ - the value which is to be interpreted
      # * +cfg_dir+ - the directory the configuration file of +key+ is
      #   contained in
      # * +list_keys+ - a list of all keys which represent comma-separated lists
      #   of values
      # * +path_keys+ - a list of all keys representing paths
      # * +cfg+ - a hash of all configuration key-value combinations parsed so
      #   far
      #
      # The +value+ of a +key+ that is found in +list_keys+ is being returned as
      # an array, while a +value+ of a +key+ in +path_keys+ is returned as
      # absolute path. If +key+ belongs to both categories its +value+ is being
      # treated accordingly.
      #
      # Returns the +value+ optionally being transformed according to the
      # additionally provided information
      def handle_key(key, value, cfg_dir, list_keys, path_keys, cfg)
        final_value = value
        # replace %{symbol} with values from already existing config values
        final_value = final_value % Hash[cfg.map { |k, v| [k.to_sym, v] }] if final_value.include? "%{"

        if list_keys.include?(key) && path_keys.include?(key)
          final_value = Rake::FileList[*(value.gsub(/\s*,\s*/, ",").split(",").uniq.map { |d| absolute_path(d.strip, cfg_dir) })]
        elsif list_keys.include?(key)
          # here we want to handle a comma separated list of entries
          final_value = value.gsub(/\s*,\s*/, ",").split(",").uniq
        elsif path_keys.include?(key)
          final_value = absolute_path(value.strip, cfg_dir)
        end
        return final_value
      end

      ##
      # Read a configuration file +path+ which may reside in +cfg_dir+
      #
      # If +path+ is an absolute path, then +cfg_dir+ is being ignored.
      # Otherwise +path+ is prefixed with +cfg_dir+.
      #
      # Returns a hash with the configuration file's read and parsed contents
      def import_config(path, cfg_dir)
        path = absolute_path(path.strip, cfg_dir)
        raise GaudiConfigurationError, "Cannot find #{path} to import" unless File.exist?(path)

        @configuration_files << path
        read_configuration(path)
      end

      ##
      # Check if a +path+ is absolute and prepend it with +cfg_dir+ otherwise
      #
      # If +path+ is an absolute path already it's being returned unmodified. If
      # it does not represent an absolute path it's being prefixed with
      # +cfg_dir+ and then being converted to an absolute path.
      #
      # Any double quotes are being removed from the passed +path+.
      #
      # Returns the absolute and conditionally prefixed equivalent of the path
      def absolute_path(path, cfg_dir)
        if Pathname.new(path.gsub("\"", "")).absolute?
          path
        else
          File.expand_path(File.join(cfg_dir, path.gsub("\"", "")))
        end
      end

      ##
      # Create or update an environment variable +envvar+ with the value +value+
      #
      # Returns the +value+ that got set
      def environment_variable(envvar, value)
        ENV[envvar] = value
      end

      ##
      # Iterate over all classes and sub-modules within +module_const+ and
      # accumulate all keys representing lists and all keys representing paths
      #
      # Returns an array containing an array of all keys representing
      # comma-separated lists and an array of all keys representing paths
      def load_key_modules(module_const)
        list_keys = []
        path_keys = []

        configuration_modules = module_const.constants
        # include all the modules you find in the namespace
        configuration_modules.each do |mod|
          klass = module_const.const_get(mod)
          extend klass
          list_keys += klass.list_keys
          path_keys += klass.path_keys
        end

        return list_keys, path_keys
      end
    end

    # The central configuration for the system
    #
    # The available functionality is extended through SystemModules modules
    class SystemConfiguration < Loader
      include EnvironmentOptions

      ##
      # Iterate through a list of configuration files +configuration_files+ and
      # return the resulting configuration as a new SystemConfiguration instance
      #
      # In case of errors upon parsing the given configurations or instantiating
      # the new instance a GaudiConfigurationError is to be raised.
      #
      # Returns a new SystemConfiguration instance
      def self.load(configuration_files)
        super(configuration_files, self)
      end

      ##
      # The main configuration file (by which the further ones were imported)
      attr_accessor :config_base
      ##
      # The current time at the completion of the instance's initialization
      attr_accessor :timestamp
      ##
      # The path of the current working directory of the process at the time of
      # the instance's initialization
      attr_accessor :workspace

      def initialize(filename)
        load_gaudi_modules(File.expand_path(filename))
        super(filename)
        @config_base = File.dirname(configuration_files.first)
        raise GaudiConfigurationError, "Setting 'base' must be defined" unless base
        raise GaudiConfigurationError, "Setting 'out' must be defined" unless out

        @workspace = Dir.pwd
        @timestamp = Time.now
      end

      def keys
        load_key_modules(Gaudi::Configuration::SystemModules)
      end

      private

      # makes sure we require the helpers from any modules defined in the configuration
      # before we start reading the configuration to ensure that extension modules work correctly
      def load_gaudi_modules(main_config_file)
        lines = File.readlines(main_config_file)
        relevant_lines = lines.select do |ln|
          /base=/ =~ ln || /gaudi_modules=/ =~ ln
        end
        cfg = parse_content(relevant_lines, File.dirname(main_config_file), *keys)
        require_modules(cfg.fetch("gaudi_modules", []), cfg["base"])
      end

      # Iterates over system_config.gaudi_modules and requires all helper files
      def require_modules(module_list, base_directory)
        module_list.each do |gm|
          mass_require(Rake::FileList["#{base_directory}/tools/build/lib/#{gm}/helpers/*.rb"])
          mass_require(Rake::FileList["#{base_directory}/tools/build/lib/#{gm}/rules/*.rb"])
        end
      end
    end

    # Adding modules in this module allows SystemConfiguration to extend it's functionality
    #
    # Modules must implement two methods:
    # list_keys returning an Array with the keys that are comma separated lists
    # and path_keys returning an Array with the keys whose value is a file path
    #
    # Modules are guaranteed a @config Hash providing access to the configuration file contents
    module SystemModules
      # The absolute basics for configuration
      module BaseConfiguration
        # :stopdoc:
        def self.list_keys
          ["gaudi_modules"]
        end

        def self.path_keys
          ["base", "out"]
        end

        # :startdoc:
        # The root path.
        # Every path in the system can be defined relative to this
        def base
          return @config["base"]
        end

        # The output directory
        def out
          return @config["out"]
        end

        # A list of module names (directories) to automatically require next to core when loading Gaudi
        def gaudi_modules
          @config["gaudi_modules"] ||= []
          return @config["gaudi_modules"]
        end

        alias_method :base_dir, :base
        alias_method :out_dir, :out
      end
    end
  end
end
