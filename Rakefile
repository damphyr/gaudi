# -*- ruby -*-
Rake.application.options.suppress_backtrace_pattern = /\.gem|ruby-2\.\d+\.\d+/
require "hoe"
require_relative('lib/gaudi/version')

task :default => [:test]


task :test do
  require 'coveralls'
  Coveralls.wear!
  require 'minitest/autorun'
  Rake::FileList["#{File.dirname(__FILE__)}/test/test_*.rb"].each do |test_file|
    require_relative "test/#{test_file.pathmap('%n')}"
  end
end
# vim: syntax=ruby
