require 'ostruct'
require 'optparse'
require 'fileutils'
require 'tmpdir'
require 'rubygems'
require 'archive/tar/minitar'

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
      options.version="HEAD"

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
          puts "Gaudi Gem v#{Gaudi::Gem::Version::STRING}"
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
        Gaudi::Gem.new(opts.project_root).project(opts.version)
      end
    end

    def initialize project_root
      @project_root=project_root
    end
    
    def project version
      raise "#{project_root} already exists!" if File.exists?(project_root) && project_root != Dir.pwd
      directory_structure
      rakefile
      main_config
      platform_config
      gaudi(version)
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
    #:nodoc:
    def gaudi(version)
      Dir.mktmpdir do |tmp|
        if File.exists?('gaudi')
          FileUtils.rm_rf('gaudi')
        end
        system 'git clone https://github.com/damphyr/gaudi gaudi'
        Dir.chdir('gaudi') do |d|
          puts "Packing #{version} gaudi version"
          cmdline="git archive --format=tar -o #{project_root}/gaudilib.tar #{version} lib/"
          system(cmdline)
        end
        puts "Unpacking in #{project_root}/tools/build"
        Dir.chdir(project_root) do |d|
          Archive::Tar::Minitar.unpack(File.join(project_root,'gaudilib.tar'), 'tools/build')
        end
        FileUtils.rm_rf(File.join(project_root,'gaudilib.tar'))
        FileUtils.rm_rf(File.join(project_root,'tools/build/pax_global_header'))
      end
    end
  end
end