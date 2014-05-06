require_relative 'errors'
module Gaudi
  module Utilities
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
    #
    #That is it switches the system configuration by reading a completely different file.
    #
    #This makes for some interesting usage when you don't want to have multiple calls
    #with a different GAUDI_CONFIG parameter
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
        end
      end
    end
    #Switches platform configuration replacing platform with the contents of the file
    #for the given block
    def switch_platform_configuration configuration_file,system_config,platform
      if block_given?
        begin
          current_config=system_config.platform_config(platform)
          new_cfg=system_config.read_configuration(configuration_file,[],[])
          system_config.set_platform_config(new_cfg,platform)
          yield
        rescue
          raise $!
        ensure
          system_config.set_platform_config(current_config,platform)
        end
      end
    end
    #Writes a file making sure the directory is created
    def write_file filename,content
      mkdir_p(File.dirname(filename),:verbose=>false)
      File.open(filename, 'wb') {|f| f.write(content) }
    end
  end
end