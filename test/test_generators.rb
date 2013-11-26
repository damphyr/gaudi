$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"
require 'rake'
require_relative 'helpers'

class TestTaskGenerators < MiniTest::Unit::TestCase
  include TestHelpers
  include Rake::DSL
  include Tasks::Build
  def setup
    directory_fixture
  end
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end
  def test_program_task
    system_config=mock()
    system_config.stubs(:source_directories).returns([File.join(File.dirname(__FILE__),'tmp')])
    system_config.stubs(:out).returns('out')
    program=Gaudi::Component.new('Foo',Gaudi::CompilationUnit::C,system_config,'mingw')
    program.stubs(:platform).returns('PC')
    program.stubs(:name).returns('foo')
    deps=program_task_dependencies(program,system_config)
    assert_equal(8, deps.size)
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(3, d.size)
    assert_equal(5, f.size)
  end
end