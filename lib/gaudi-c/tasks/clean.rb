namespace :clean do
  desc "Removes the compilation command files"
  task :breadcrumbs do
    rm_rf(FileList[*$configuration.source_directories.pathmap("%p/**/*.{compile,assemble}")], :verbose => false) if $configuration
  end
end
