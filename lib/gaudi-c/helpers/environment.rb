module Gaudi
  module Configuration
    module EnvironmentOptions
      #Defines the component name to work with, raises GaudiConfigurationError if not defined
      def component
        mandatory('COMPONENT')
      end
      #Defines the deployment name to work with, raises GaudiConfigurationError if not defined
      def deployment
        mandatory('DEPLOYMENT')
      end
    end
  end
end