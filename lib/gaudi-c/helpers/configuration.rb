require "delegate"
require_relative "operations"

module Gaudi
  module Configuration
    # Switches platform configuration replacing platform with the contents of the file
    # for the given block
    def self.switch_platform_configuration(configuration_file, system_config, platform)
      if block_given?
        begin
          puts "Switching platform configuration for #{platform} to #{configuration_file}"
          current_config = system_config.platform_config(platform)
          new_cfg_data = system_config.read_configuration(File.expand_path(configuration_file))
          system_config.set_platform_config(PlatformConfiguration.new(platform, new_cfg_data), platform)
          yield
        rescue
          raise
        ensure
          puts "Switching back platform configuration for #{platform}"
          system_config.set_platform_config(current_config, platform)
        end
      end
    end

    module SystemModules
      # Platform configuration methods that provide more control over the raw Hash platform data
      module PlatformConfiguration
        include ConfigurationOperations
        # :stopdoc:
        def self.list_keys
          ["platforms", "sources"]
        end

        def self.path_keys
          ["sources"]
        end

        # :startdoc:
        # List of available platforms
        def platforms
          return @config["platforms"]
        end

        # List of directories containing sources
        def sources
          @config["sources"].map { |d| File.expand_path(d) }
        end

        # returns the platform configuration hash
        def platform_config(platform)
          return @config["platform_data"][platform]
        end

        # Sets the platform configuration hash
        #
        # The standard platform specific configuration options
        # are described in PlatformConfiguration
        def set_platform_config(platform_data, platform)
          @config["platform_data"][platform] = platform_data
        end

        # Returns the file extensions for the given platform
        def extensions(platform)
          if @config["platform_data"].keys.include?(platform)
            return @config["platform_data"][platform].extensions
          else
            raise GaudiConfigurationError, "Unknown platform #{platform}"
          end
        end

        # Return the auto_rules flag.
        #
        # This is false by default
        def auto_rules?
          @config.fetch("auto_rules", false)
        end

        alias_method :source_directories, :sources
        # :startdoc:
        # Source file extensions
        def source_extensions(platform)
          return platform_config(platform)["source_extensions"].gsub(", ", ",")
        end

        # Header file extensions
        def header_extensions(platform)
          return platform_config(platform)["header_extensions"].gsub(", ", ",")
        end

        # A list of paths to be used as include paths when compiling
        #
        # Relative paths are interpreted relative to the main configuration file's location
        def external_includes(platform)
          includes = platform_config(platform).fetch("incs", "")
          return includes.split(",").map { |d| absolute_path(d.strip, config_base) }
        end

        # Returns an array with paths to the external libraries as defined in the platform configuration
        #
        # To do this it uses the PlatformConfiguration.external_lib_cfg file to replace the library tokens with path values
        #
        # If the file exists under trunk/lib the entry is the full path to the file
        # otherwise the entry from external_lib_cfg is returned as is (which works for system libraries i.e. winmm.lib, winole.lib etc.)
        def external_libraries(platform)
          external_lib_tokens = platform_config(platform).fetch("libs", "").split(",").map { |el| el.strip }
          return interpret_library_tokens(external_lib_tokens, external_libraries_config(platform), self.config_base)
        end

        # Returns an array with paths to the external libraries in use for unit tests as defined in the platform configuration
        #
        # To do this it uses the PlatformConfiguration.external_lib_cfg file to replace the library tokens with path values
        #
        # If the file exists under trunk/lib the entry is the full path to the file
        # otherwise the entry from external_lib_cfg is returned as is (which works for system libraries i.e. winmm.lib, libsqlite3 etc.)
        def unit_test_libraries(platform)
          external_lib_tokens = platform_config(platform).fetch("unit_test_libs", "").split(",").map { |el| el.strip }
          return interpret_library_tokens(external_lib_tokens, external_libraries_config(platform), self.config_base)
        end

        # Loads and returns the external libraries configuration
        #
        # The configuration is a {name=>path} hash and is used to
        # replace the library names used in the PLatform.external_libraries setting
        def external_libraries_config(platform)
          lib_config = platform_config(platform).fetch("lib_cfg", "")
          raise GaudiConfigurationError, "Missing lib_cfg entry for platform #{platform}" if lib_config.empty?

          external_lib_cfg = absolute_path(lib_config, config_base)
          raise GaudiConfigurationError, "No external library configuration for platform #{platform}" unless external_lib_cfg

          if File.exist?(external_lib_cfg)
            return YAML.load(File.read(external_lib_cfg))
          else
            raise GaudiConfigurationError, "Cannot find external library configuration #{external_lib_cfg} for platform #{platform}"
          end
        end

        # A list of files to be copied together with every program
        def resources(platform)
          return platform_config(platform).fetch("resources", "").split(",").map { |d| absolute_path(d.strip, config_base) }
        end
      end
    end

    # Adding modules in this module allows BuildConfiguration to extend it's functionality
    #
    # Modules must implement two methods:
    # list_keys returning an Array with the keys that are comma separated lists
    # and path_keys returning an Array with the keys whose value is a file path
    #
    # Modules are guaranteed a @config Hash providing access to the configuration file contents
    module BuildModules
      # Configuration directoves for simple components
      module ComponentConfiguration
        # :stopdoc:
        def self.list_keys
          ["deps", "incs"]
        end

        def self.path_keys
          ["incs"]
        end

        # :startdoc:
        # The prefix is the name of the component
        #
        # It's called prefix for historical reasons ;)
        def prefix
          return @config.fetch("prefix", "")
        end

        # A list of prefixes that represent dependencies to the system's
        # internal components
        def dependencies
          return @config.fetch("deps", Rake::FileList.new)
        end

        # A list of paths to be used as include paths when compiling
        #
        # Relative paths are interpreted relative to the configuration file's location
        def external_includes
          return @config.fetch("incs", Rake::FileList.new)
        end

        alias_method :incs, :external_includes
        alias_method :deps, :dependencies
      end

      # Configuration directives for programs.
      #
      # For a Gaudi::Program instance these are added in addition to the ComponentConfiguration directives
      module ProgramConfiguration
        include ConfigurationOperations

        # :stopdoc:
        def self.list_keys
          ["libs", "resources", "shared_deps"]
        end

        def self.path_keys
          ["resources"]
        end

        # :startdoc:
        # A list of library files to be added when linking
        #
        # Relative paths are interpreted relative to the configuration file's location
        def external_libraries(system_config, platform)
          return interpret_library_tokens(@config.fetch("libs", []), system_config.external_libraries_config(platform), system_config.config_base)
        end

        # Option key can be one of compiler_options, assembler_options, lirbary_options or linker_options
        #
        # These are added to the platform configuration options, they do NOT override them
        def option(key)
          return @config.fetch(key, "")
        end

        # List of paths to resource files that are copied with the program build
        def resources
          return @config.fetch("resources", [])
        end

        # A list of prefixes that represent shared dependencies to the system's
        # internal components
        def shared_dependencies
          return @config.fetch("shared_deps", Rake::FileList.new)
        end

        alias_method :libs, :external_libraries
      end
    end

    # For each set of sources we identify as a unit/component/group BuildConfiguration corresponds
    # to the configuration file that describe the dependencies to the rest of the system.
    class BuildConfiguration < Loader
      attr_writer :configuration_files, :config
      # I guess this is what you call a Factory Method?
      def self.load(configuration_files)
        cfg = nil
        configuration_files.each do |cfg_file|
          if cfg
            cfg.merge(cfg_file)
          else
            ld = Loader.new(cfg_file)
            raise GaudiConfigurationError, "No prefix in configuration #{cfg_file}" unless ld.config["prefix"]

            cfg = BuildConfiguration.new(ld.config["prefix"])
            cfg.merge(cfg_file)
            cfg.configuration_files << cfg_file
          end
        end
        raise GaudiConfigurationError, "No BuildConfiguration configuration files in '#{configuration_files}'" unless cfg

        return cfg
      end

      def initialize(prefix)
        @config = { "prefix" => prefix }
        @configuration_files = Rake::FileList.new
        keys
      end

      def keys
        load_key_modules(Gaudi::Configuration::BuildModules)
      end
    end

    class SystemConfiguration < Loader
      alias_method :_original_init, :initialize

      def initialize(filename)
        _original_init(filename)
        load_platform_configurations()
      end

      # :stopdoc:
      def load_platform_configurations
        @config["platform_data"] = {}
        @config["platforms"] ||= []
        platforms.each do |platform_name|
          path = @config[platform_name]
          path = File.expand_path(File.join(@config_base, path)) if !Pathname.new(path).absolute?

          pdata = read_configuration(path)
          @configuration_files << path
          @config["platform_data"][platform_name] = PlatformConfiguration.new(platform_name, pdata)
        end
      end

      # :startdoc:
    end

    # PlatformConfiguration encapsulates the platform specific part of Gaudi's configuration
    #
    # For more details check https://github.com/damphyr/gaudi/blob/master/doc/CONFIGURATION.md
    class PlatformConfiguration < DelegateClass(::Hash)
      # PlatformCofiguration.extend extends the platform configuration
      # compiler_options, assembler_options, library_options and linker_options parameters
      # with the values given in the component configuration for the code given in the block
      #
      #  PlatformConfiguration.extend(component,system_config) do
      #        perform build actions with extended platform options
      #  end
      def self.extend(component, system_config)
        if block_given?
          begin
            current_config = system_config.platform_config(component.platform)
            # extend the platform configuration with the component configuration settings
            new_cfg = current_config.dup
            system_config.source_extensions(component.platform).split(",").map { |ext| "compiler_options_#{ext.strip}" } + ["compiler_options", "assembler_options", "library_options", "linker_options"].each do |key|
              new_cfg[key] = "#{current_config[key]} #{component.configuration.option(key)}"
            end
            system_config.set_platform_config(new_cfg, component.platform)
            yield
          rescue
            raise
          ensure
            system_config.set_platform_config(current_config, component.platform)
          end
        else
          raise GaudiError, "PlatformConfiguration.extend requires a block"
        end
      end

      attr_reader :name

      def initialize(name, platform_data)
        super(platform_data)
        @name = name
        __getobj__.merge!(platform_data)
        validate
      end

      def extensions
        [__getobj__["object_extension"], __getobj__["library_extension"], __getobj__["executable_extension"]]
      end

      private

      def validate
        ["source_extensions", "header_extensions", "object_extension", "library_extension", "executable_extension"].each do |key|
          raise GaudiConfigurationError, "Define #{key} for platform #{name}" unless self.keys.include?(key)
        end
        unless self.keys.include?("source_directories")
          self["source_directories"] = "common,#{name}"
        end
      end
    end
  end
end
