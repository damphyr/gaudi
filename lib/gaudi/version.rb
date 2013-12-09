module Gaudi
  #Gaudi follows SemVer evn though it's not a gem
  module Version
    #Major version
    MAJOR=0
    #Minor version
    MINOR=0
    #Tiny version
    TINY=1
    #All-in-one
    STRING=[MAJOR,MINOR,TINY].join('.')
  end
end
