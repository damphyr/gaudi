# encoding: UTF-8
require 'rake/dsl_definition'
require 'rake/file_list'
require_relative 'gaudi/helpers/utilities'
include Rake::DSL
include Gaudi::Utilities

#load every file you find in the helpers directory
mass_require(Rake::FileList["#{File.join(File.dirname(__FILE__),'gaudi/helpers')}/*.rb"].exclude("utilities.rb"))

module Gaudi::Utilities
  #Reads the configuration and sets the environment up
  #
  #This is the system's entry point
  def env_setup work_dir
    #Ensure that stdout and stderr output is properly ordered
    $stdout.sync=true
    $stderr.sync=true
    #Tell rake not to truncate it's task output
    Rake.application.terminal_columns = 999
    unless $configuration
      #we're looking for the configuration
      if ENV['GAUDI_CONFIG']
        system_config=Gaudi::Configuration::SystemConfiguration.load([ENV['GAUDI_CONFIG']])
        system_config.workspace=File.expand_path(work_dir)
        if system_config.auto_rules? 
          include Gaudi::Rules::Build
          all_rules(system_config)
        end
        $configuration=system_config
      else
        raise GaudiError,"Did not specify a configuration.\n Add GAUDI_CONFIG=path/to/config to the commandline or specify the GAUDI_CONFIG environment variable"
      end
    end
  end
end
