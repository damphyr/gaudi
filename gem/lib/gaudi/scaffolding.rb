require 'ostruct'
require 'optparse'
require 'fileutils'
require 'tmpdir'
require 'rubygems'
require 'minitar'

module Gaudi
  class GemError <RuntimeError
  end
  class Gem
    MAIN_CONFIG="system.cfg"
    PLATFORM_CONFIG="foo.cfg"
    REPO="https://github.com/damphyr/gaudi"

    attr_reader :project_root,:gaudi_home
    #:nodoc:
    def self.options arguments
      options = OpenStruct.new
      options.project_root= Dir.pwd
      options.verbose= false
      options.scaffold= false
      options.update= false
      options.library= false
      options.version= "HEAD"

      opt_parser = OptionParser.new do |opts|
        opts.banner = "Usage: gaudi [options]"
        opts.separator "Make sure GitHub is accessible via https and git is on the PATH environment"
        opts.separator ""
        opts.separator "Commands:"

        opts.on("-s", "--scaffold PROJECT_PATH","Create a Gaudi scaffold in PROJECT_PATH") do |proot|
          options.project_root=File.expand_path(proot)
          options.scaffold=true
          options.update=false
        end
        opts.on("-u", "--update PROJECT_PATH","Update Gaudi core from GitHub on project at PROJECT_PATH") do |proot|
          options.project_root=File.expand_path(proot)
          options.update=true
          options.scaffold=false
        end
        opts.on("-l", "--lib NAME URL PROJECT_PATH","Pull/Update Gaudi library from URL on project at PROJECT_PATH") do |name|
          options.library=true
          options.update=false
          options.scaffold=false
          options.lib=name
          if ARGV.size<2
            raise GemError, "Missing parameters!"
          end
          url=ARGV.shift
          proot=ARGV.shift
          options.url=url
          options.project_root=File.expand_path(proot)
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
      begin
        opt_parser.parse!(arguments)
      rescue GemError
        puts $!.message
        exit 1
      end
      return options
    end
    #:nodoc:
    def self.run args
      opts=options(args)
      begin
        if opts.scaffold
          Gaudi::Gem.new(opts.project_root).project(opts.version)
        elsif opts.update
          Gaudi::Gem.new(opts.project_root).update(opts.version)
        elsif opts.library
          Gaudi::Gem.new(opts.project_root).library(opts.lib,opts.url,opts.version)
        end
      rescue Gaudi::GemError
        puts $!.message
        exit 1
      end
    end

    def initialize project_root
      @project_root=project_root
      @gaudi_home=File.join(project_root,"tools","build")
    end
    
    def project version
      raise GemError, "#{project_root} already exists!" if File.exists?(project_root) && project_root != Dir.pwd
      check_for_git
      directory_structure
      rakefile
      main_config
      platform_config
      lib_config
      core("gaudi",REPO,version,"lib")
    end

    def update version
      raise GemError, "#{gaudi_home} is missing! Try creating a new Gaudi project first." unless File.exists?(gaudi_home)
      check_for_git
      puts "Removing old gaudi installation"
      FileUtils.rm_rf(File.join(gaudi_home,"lib/gaudi"))
      core(version,REPO,"lib/gaudi lib/gaudi.rb")
    end

    def library lib,source_url,version
      raise GemError, "#{gaudi_home} is missing! Try creating a new Gaudi project first." unless File.exists?(gaudi_home)
      #check_for_git
      puts "Removing old #{lib} installation"
      FileUtils.rm_rf(File.join(gaudi_home,"lib/#{lib}"))
      puts "Pulling #{version} from #{source_url}"
      core(lib,source_url,version,"lib/#{lib}")
    end
    #:stopdoc:
    def check_for_git
      raise GemError, "Could not find git. Make sure it is in the PATH" unless system("git --version")
    end
    
    def directory_structure
      puts "Creating Gaudi filesystem structure at #{project_root}"
      structure=["doc","lib","src/deployments","src/common","test","tools/build","tools/templates"]
      structure.each do |dir|
        FileUtils.mkdir_p File.join(project_root,dir),:verbose=>false
      end
    end
    
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
    
    def lib_config
      puts "Generating example library configuration file"
      config_file=File.join(project_root,"tools/build/libs.yaml")
      if File.exists?(config_file)
        puts "libs.yaml exists, skipping generation"
      else
        configuration_content="---\n"
        File.open(config_file, 'wb') {|f| f.write(configuration_content) }
      end
    end

    def core(lib,url,version,lib_items)
      Dir.mktmpdir do |tmp|
        if pull_from_repo(url,tmp)
          pkg=archive(version,File.join(tmp,"gaudi"),project_root,lib_items)
          unpack(pkg,gaudi_home)
        else
          raise GemError, "Cloning the Gaudi repo failed. Check that git is on the PATH and that #{REPO} is accessible"
        end
      end
    end

    def pull_from_repo repository,tmp
      tmp_dir=File.join(tmp,'gaudi')
      FileUtils.rm_rf(tmp_dir) if File.exists?(tmp_dir)
      system "git clone #{repository} \"#{tmp_dir}\""
    end
    
    def archive version,clone_path,prj_root,lib_items
      pkg=File.expand_path(File.join(prj_root,"gaudipkg.tar"))
      Dir.chdir(clone_path) do |d|
        puts "Packing #{version} gaudi version in #{pkg}"
        cmdline="git archive --format=tar -o \"#{pkg}\" #{version} #{lib_items}"
        system(cmdline)
      end
      return pkg
    end
    
    def unpack pkg,home
      puts "Unpacking in #{home}"
      Dir.chdir(home) do |d|
        Minitar.unpack(pkg, home)
      end
      FileUtils.rm_rf(pkg)
      FileUtils.rm_rf(File.join(home,'pax_global_header'))
    end
    #:startdoc:
  end
end