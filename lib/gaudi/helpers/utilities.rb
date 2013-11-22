require 'gaudi/helpers/errors'
#Requires all files defined in the list printing out errors 
#but without interrupting on error
def mass_require filelist
  filelist.each do |helper|
    begin
      require helper 
    rescue LoadError
      puts "Could not load #{helper} : #{$!.message}"
    rescue
      puts "Could not load #{helper} : #{$!.message}"
    end
  end
end

#Switches the configuration for the given block
def switch_configuration configuration_file
  if block_given?
    current_configuration =  ENV['GAUDI_CONFIG']
    if File.expand_path(configuration_file) != File.expand_path(current_configuration)
      begin
        puts "Switching configuration to #{configuration_file}"
        $configuration=nil
        ENV['GAUDI_CONFIG'] = configuration_file
        $configuration=Gaudi::Configuration::SystemConfiguration.load([ENV['GAUDI_CONFIG']])
        yield
      ensure
        puts "Switching configuration back to #{current_configuration}"
        $configuration=nil
        ENV['GAUDI_CONFIG'] = current_configuration
        $configuration=Gaudi::Configuration::SystemConfiguration.load([ENV['GAUDI_CONFIG']])
      end
    else
      yield
    end
  end
end