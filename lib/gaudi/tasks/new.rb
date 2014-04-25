namespace :new do
  desc "Directory structure for a new project. Uses PROJECT_ROOT or the current directory"
  task :project do |t|
    project_root=File.expand_path(ENV.fetch('PROJECT_ROOT',Dir.pwd))
    raise "#{project_root} already exists!" if File.exists?(project_root) && project_root != Dir.pwd
    puts "Creating Gaudi filesystem structure at #{project_root}"
    structure=["doc","lib","src","test","tools/build","tools/templates"]
    structure.each do |dir|
      mkdir_p File.join(project_root,dir),:verbose=>false
    end

    puts "Generating main Rakefile"
    rakefile=File.join(project_root,"Rakefile")
    if File.exists?(rakefile)
      puts "Rakefile exists, skipping generation"
    else
      rakefile_content=<<-EOT
require_relative 'tools/build/lib/gaudi'
env_setup(File.dirname(__FILE__))
#add the custom stuff here
      EOT
      File.open(rakefile, 'wb') {|f| f.write(rakefile_content) }
    end
    #pull the gaudi sources from GitHub
    puts "Pulling Gaudi sources"
    #
    puts "Generating initial configuration file"
    config_file=File.join(project_root,"tools/build/build.cfg")
    if File.exists?(config_file)
      puts "build.cfg exists, skipping generation"
    else
      configuration_content=<<-EOT
#the project root directory
base=../../
#the build output directory
out=../../out
sources=../../src/
#enumerate the platforms i.e. platforms=mingw,ms,arm
#platforms=
#add a platform=platform.cfg for each platform pointing to the platform configuration
      EOT
      File.open(config_file, 'wb') {|f| f.write(configuration_content) }
    end
    puts "Done!"
  end
end
