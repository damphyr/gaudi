#Example rules matching the scaffolding configuration
#
#Replace foo with the platform name
#
#Replace the extensions with the extensions defined in the platform configuration

#rule /foo\/.*\.e/ do |t|
#  include Gaudi::ArtifactAdapters::Build
#  build(t,$configuration,'foo')
#end

#rule /foo\/.*\.o/ do |t|
#  include Gaudi::ArtifactAdapters::Build
#  compile(t,$configuration,'foo')
#end
