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
    #Writes a file making sure the directory is created
    def write_file filename,content
      mkdir_p(File.dirname(filename),:verbose=>false)
      File.open(filename, 'wb') {|f| f.write(content) }
    end
  end
end