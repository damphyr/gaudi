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