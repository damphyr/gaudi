namespace :clean do
  desc "Removes the compilation command files"
  task :breadcrumbs do
    if $configuration
      rm_rf(FileList[*$configuration.source_directories.pathmap('%p/**/*.{compile,assemble}')],:verbose=>false)
    end
  end
end