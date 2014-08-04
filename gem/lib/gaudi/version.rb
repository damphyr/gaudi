module Gaudi
  #Gaudi follows SemVer even so does it's gem, but the're two separate things
  class Gem
    module Version
      #Major version
      MAJOR=0
      #Minor version
      MINOR=2
      #Tiny version
      TINY=1
      #All-in-one
      STRING=[MAJOR,MINOR,TINY].join('.')
    end
  end
end
