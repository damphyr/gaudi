require 'ostruct'
require 'optparse'
require 'fileutils'

module Gaudi
  class Gem
    MAIN_CONFIG="system.cfg"
    PLATFORM_CONFIG="foo.cfg"
    attr_reader :project_root
    #:nodoc:
    def self.options arguments
      options = OpenStruct.new
      options.project_root = Dir.pwd
      options.verbose = false
      options.scaffold=false

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: gaudi [options]"
        opts.separator ""
        opts.separator "Commands:"

        opts.on("-s", "--scaffold PATH","Create a Gaudi scaffold in PATH") do |proot|
          options.project_root=File.expand_path(proot)
          options.scaffold=true
        end
        opts.separator ""
        opts.separator "Common options:"
        # Boolean switch.
        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options.verbose = v
        end
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.on_tail("--version", "Show version") do
          puts Gaudi::Gem::Version::STRING
          exit
        end
      end
      opt_parser.parse!(arguments)
      return options
    end
    #:nodoc:
    def self.run args
      opts=options(args)
      if opts.scaffold
        Gaudi::Gem.new(opts.project_root).project
      end
    end

    def initialize project_root
      @project_root=project_root
    end
    
    def project
      raise "#{project_root} already exists!" if File.exists?(project_root) && project_root != Dir.pwd
      directory_structure
      rakefile
      main_config
      #platform_config
    end
    #:nodoc:
    def directory_structure
      puts "Creating Gaudi filesystem structure at #{project_root}"
      structure=["doc","lib","src","test","tools/build","tools/templates"]
      structure.each do |dir|
        FileUtils.mkdir_p File.join(project_root,dir),:verbose=>false
      end
    end
    #:nodoc:
    def rakefile
      puts "Generating main Rakefile"
      rakefile=File.join(project_root,"Rakefile")
      if File.exists?(rakefile)
        puts "Rakefile exists, skipping generation"
      else
        rakefile_content=<<-EOT
  require_relative 'tools/build/lib/gaudi'
  env_setup(File.dirname(__FILE__))
  require_relative 'tools/build/lib/gaudi/tasks'
        EOT
        File.open(rakefile, 'wb') {|f| f.write(rakefile_content) }
      end
    end
    #:nodoc:
    def main_config
      puts "Generating initial configuration file"
      config_file=File.join(project_root,"tools/build/#{MAIN_CONFIG}")
      if File.exists?(config_file)
        puts "#{MAIN_CONFIG} exists, skipping generation"
      else
        configuration_content=File.read(File.join(File.dirname(__FILE__),'templates/main.cfg.template'))
        File.open(config_file, 'wb') {|f| f.write(configuration_content) }
      end
    end
    #:nodoc:
    def platform_config
      puts "Generating example platform configuration file"
      config_file=File.join(project_root,"tools/build/#{PLATFORM_CONFIG}")
      if File.exists?(config_file)
        puts "#{PLATFORM_CONFIG} exists, skipping generation"
      else
        configuration_content=File.read(File.join(File.dirname(__FILE__),'templates/platform.cfg.template'))
        File.open(config_file, 'wb') {|f| f.write(configuration_content) }
      end
    end
  end
end