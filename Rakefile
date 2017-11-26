# -*- ruby -*-
Rake.application.options.suppress_backtrace_pattern = /\.gem|ruby-2\.\d+\.\d+/
require "hoe"
require_relative('lib/gaudi/version')

task :default => [:test]

task :"test:gaudi" do
  require 'coveralls'
  Coveralls.wear!
  require 'minitest/autorun'
  Rake::FileList["#{File.dirname(__FILE__)}/test/gaudi/test_*.rb"].each do |test_file|
    require_relative "test/gaudi/#{test_file.pathmap('%n')}"
  end
end
# vim: syntax=ruby

task :test=> [:"test:gaudi"]