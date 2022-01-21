##
# Base exception type of Gaudi
#
# This exception is the base of the exception hierarchy of Gaudi. If Gaudi code
# raises neither this exception nor an exception derived from this one, then
# it's a bug.
class GaudiError < RuntimeError
end

##
# Exception which is being raised if an error occurs during configuration
# handling
#
# This exception can be caused by a variety of circumstances, some exemplary
# ones being:
# * a mandatory configuration option being missing
# * an invalid configuration option being encountered
# * an imported configuration file being missing
# * syntax errors in configuration files
class GaudiConfigurationError < GaudiError
end
