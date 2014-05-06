require_relative '../gaudi'

#load every file you find in the tasks directory
mass_require(FileList["#{File.join(File.dirname(__FILE__),'tasks')}/*.rb"])
mass_require(FileList["#{File.join(File.dirname(__FILE__),'../custom/tasks')}/*.rb"])