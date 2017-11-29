namespace :unit do
  desc "Builds the unit tests for COMPONENT on the MinGW platform"
  task :'mingw' do
    include UnitTestOperations
    component=Gaudi::Component.new($configuration.component,$configuration,'mingw')
    ut=unit_test_task(component,$configuration)
    Rake::Task[ut].invoke
    sh(ut.name)
  end
end

namespace :clean do
  task :all => :test_runners
  task :test_runners do |t|
    rm_rf(FileList[*$configuration.sources.pathmap("%p/**/*Runner.c")],:verbose=>false)
    puts "#{t.name} done!"
  end
end