module Gaudi
  #Gaudi follows SemVer even though it's not a gem
  module Version
    #Major version
    MAJOR=0
    #Minor version
    MINOR=10
    #Tiny version
    TINY=1
    #All-in-one
    STRING=[MAJOR,MINOR,TINY].join('.')
  end
end
