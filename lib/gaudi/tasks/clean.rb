namespace :clean do
  desc "Removes the output directory"
  task :wipe do |t|
    if $configuration
      rm_rf(FileList[$configuration.out],:verbose=>false)
    end
    puts "#{t.name} done!"
  end
  desc "Removes the compilation command files"
  task :breadcrumbs do
    if $configuration
      rm_rf(FileList[*$configuration.source_directories.pathmap('%p/**/*.{compile,assemble}')],:verbose=>false)
    end
  end
end