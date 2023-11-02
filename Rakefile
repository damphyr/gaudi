# -*- ruby -*-
Rake.application.options.suppress_backtrace_pattern = /\.gem|ruby-[23]\.\d+\.\d+/
require "hoe"
require_relative("lib/gaudi/version")
require "minitest/autorun"
require "coveralls"
Coveralls.wear!

task :default => [:test]
desc "Run gaudi core tests"
task :"test:gaudi" do
  Rake::FileList["#{File.dirname(__FILE__)}/test/gaudi/test_*.rb"].each do |test_file|
    require_relative "test/gaudi/#{test_file.pathmap("%n")}"
  end
end
desc "Run the C module tests"
task :"test:gaudi-c" do
  Rake::FileList["#{File.dirname(__FILE__)}/test/gaudi-c/test_*.rb"].each do |test_file|
    require_relative "test/gaudi-c/#{test_file.pathmap("%n")}"
  end
end

task :test => [:"test:gaudi", :"test:gaudi-c"]

# vim: syntax=ruby
