#Functions that return platform dependent information
#
#The most basic of these is the extensins used for the various build artifacts.
#
#To add support for a new platform create a PlatformOperation::Name module with
#a class method extensions that returns [object,library,executable]
#
#See PlatformOperations::PC or PlatformOperations::RX for an example
module PlatformOperations
  #Support for the Microsoft compiler
  module PC
    def self.extensions
      ['.obj','.lib','.exe']
    end
  end
  #Renesas RX toolchain support
  module RX
    def self.extensions
      ['.obj','.lib','.abs']
    end
  end
  #Support for the mingw compiler on windows
  module MINGW
    def self.extensions
      ['.obj','.lib','.exe']
    end
  end
  #returns the extensions for the platform as [object,library,executable]
  def extensions platform
    if PlatformOperations.constants.include?(platform.to_sym)
      return PlatformOperations.const_get(platform).extensions
    else
      raise GaudiError,"Unknown platform #{platform}"
    end
  end
  #Returns true if the file given is a library for the given platform
  def is_library? filename,platform
    obj,lib,exe=*extensions(platform)
    return filename.end_with?(lib)
  end
end

#Methods to enforce naming conventions for various build artifacts
module Filenames
  def executable component,system_config
    File.join(system_config.out,component.platform,component.name,"#{component.name}#{ext_exe}")
  end
end