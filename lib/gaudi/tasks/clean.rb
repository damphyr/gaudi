namespace :clean do
  desc "Removes the output directory"
  task :wipe do |t|
    rm_rf(FileList[$configuration.out], :verbose => false) if $configuration
    puts "#{t.name} done!"
  end
end
