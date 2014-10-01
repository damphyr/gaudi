module Gaudi
  #Gaudi follows SemVer even though it's not a gem
  module Version
    #Major version
    MAJOR=0
    #Minor version
    MINOR=7
    #Tiny version
    TINY=4
    #All-in-one
    STRING=[MAJOR,MINOR,TINY].join('.')
  end
end
