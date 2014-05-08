#Rule for MINGW deployment executables
rule /mingw\/.*\.exe/ do |t|
  include Gaudi::ArtifactAdapters::Build
  mkdir_p(File.dirname(t.name),:verbose=>false)
  build(t.name,$configuration,'mingw')
end
#Objects
rule /mingw\/.*\.obj/ do |t|
  include Gaudi::ArtifactAdapters::Build
  mkdir_p(File.dirname(t.name),:verbose=>false)
  sources = t.prerequisites.select{|pr| is_source?(pr)}
  compile(sources[0],$configuration,'mingw')
end