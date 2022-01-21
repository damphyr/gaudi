require_relative "errors"

module Gaudi
  ##
  # Module of helper methods to enhance the handling of environment variables
  module EnvironmentHelpers
    ##
    # Query the value of the environment variable +env_var+ and raise a
    # GaudiError if it does not exist
    #
    # Returns the value of the environment variable +env_var+
    def mandatory(env_var)
      ENV[env_var] || raise(GaudiError, "Environment variable '#{env_var}' not defined.\nValue mandatory for the current task.")
    end
  end

  module Configuration
    ##
    # Module encapsulating environment variables which are being used to adjust
    # the Gaudi builder's configuration
    #
    # This module is being mixed in with SystemConfiguration.
    module EnvironmentOptions
      include EnvironmentHelpers

      ##
      # Query the value of the +GAUDI_CONFIG+ environment variable used to find
      # the system configuration file
      #
      # A GaudiError is being raised if this environment variable doesn't exist.
      #
      # Returns the value of the environment variable +GAUDI_CONFIG+
      def gaudi_config
        mandatory("GAUDI_CONFIG")
      end

      ##
      # Query the value of the +USER+ environment variable used to find the user
      # name to work with
      #
      # A GaudiError is being raised if this environment variable doesn't exist.
      #
      # Returns the value of the environment variable +USER+
      def user!
        mandatory("USER")
      end

      ##
      # Query the value of the +USER+ environment variable used to find the user
      # name to work with
      #
      # If the +USER+ environment variable does not exist nil is being returned.
      #
      # Returns the value of the environment variable +USER+ or nil
      def user
        return ENV["USER"]
      end
    end
  end
end
