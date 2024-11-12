# Gaudi is a collection of helpers and tools that together with a small set of conventions and rake
# allows you to create complex build systems.
module Gaudi
  ##
  # Module encapsulating version information of Gaudi
  #
  # Gaudi follows semantic versioning (https://semver.org/) even though it's not
  # a gem per se.
  module Version
    ##
    # The major version of Gaudi
    MAJOR = 1

    ##
    # The minor version of Gaudi
    MINOR = 1
    ##
    # The tiny version of Gaudi
    TINY = 2

    ##
    # The complete version of Gaudi as a string
    STRING = [MAJOR, MINOR, TINY].join(".")
  end
end
