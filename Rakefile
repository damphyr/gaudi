# -*- ruby -*-

require "hoe"
require_relative('lib/gaudi/version')

# Hoe.plugin :compiler
# Hoe.plugin :gem_prelude_sucks
# Hoe.plugin :inline
# Hoe.plugin :racc
# Hoe.plugin :rcov
# Hoe.plugin :rubyforge

Hoe.spec "gaudi" do |prj|
  developer("Vassilis Rizopoulos", "vassilisrizopoulos@gmail.com")
  license "MIT"
  prj.version = Gaudi::Version::STRING
  prj.summary='A collection of helpers and an opinionated implementation of a C build system on top of rake'
  prj.description=prj.paragraphs_of('README.md',1..5).join("\n\n")
  prj.local_rdoc_dir='doc/rdoc'
  prj.readme_file="README.md"
end

Rake::Task[:test].clear

task :test do
  require 'coveralls'
  Coveralls.wear!
  require 'minitest/autorun'
  Rake::FileList["#{File.dirname(__FILE__)}/test/test_*.rb"].each do |test_file|
    require_relative "test/#{test_file.pathmap('%n')}"
  end
end
# vim: syntax=ruby
