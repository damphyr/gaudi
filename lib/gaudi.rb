# encoding: UTF-8
require 'rake/dsl_definition'
require 'rake/file_list'
require 'gaudi/helpers/utilities'
include Rake::DSL

#load every file you find in the helpers directory
mass_require(Rake::FileList["#{File.join(File.dirname(__FILE__),'gaudi/helpers')}/*.rb"].exclude("utilities.rb"))

#Reads the configuration and sets the environment up
#
#This is the system's entry point
def env_setup current_dir
  #Ensure that stdout and stderr output is properly ordered
  $stdout.sync=true
  $stderr.sync=true
  #Tell rake not to truncate it's task output
  Rake.application.terminal_columns = 999
  unless $configuration
    #we're looking for the configuration
    if ENV['GAUDI_CONFIG']
      system_config=gaudi_configuration
      system_config.current_dir=File.expand_path(current_dir)
      $configuration=system_config
    else
      if !ARGV.empty? && ARGV.include?('T')
        raise GaudiError,"Did not specify a configuration.\n Add GAUDI_CONFIG=path/to/config to the commandline or specify the GAUDI_CONFIG environment variable"
      end
    end
  end
end