#General Gaudi error
#
#If at any point there is a different exception type in the code then it's going to be a bug
class GaudiError< RuntimeError
end

class GaudiConfigurationError< GaudiError
end