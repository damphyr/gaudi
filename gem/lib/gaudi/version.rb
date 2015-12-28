module Gaudi
  #Gaudi follows SemVer and so does it's gem, but they're two separate things
  class Gem
    module Version
      #Major version
      MAJOR=0
      #Minor version
      MINOR=3
      #Tiny version
      TINY=0
      #All-in-one
      STRING=[MAJOR,MINOR,TINY].join('.')
    end
  end
end
