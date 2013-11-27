$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"
require 'rake'
require_relative 'helpers'

class TestTaskGenerators < MiniTest::Unit::TestCase
  include TestHelpers
  include Rake::DSL
  include Gaudi::Tasks::Build
  def setup
    directory_fixture
  end
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end

  def system_configuration_mock
    system_config=mock()
    system_config.stubs(:source_directories).returns([File.join(File.dirname(__FILE__),'tmp')])
    system_config.stubs(:out).returns('out')
    system_config.stubs(:default_compiler_mode).returns('C')
    system_config
  end

  def test_program_task
    system_config=system_configuration_mock
    program=Gaudi::Component.new('FOO',system_config,'mingw')
    program.stubs(:platform).returns('PC')
    program.stubs(:name).returns('FOO')
    deps=program_task_dependencies(program,system_config)
    assert_equal(8, deps.size)
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(3, d.size)
    assert_equal(5, f.size)
  end

  def test_library_task
    system_config=system_configuration_mock
    component=Gaudi::Component.new('FOO',system_config,'mingw')
    component.stubs(:platform).returns('PC')
    component.stubs(:name).returns('FOO')
    deps=library_task_dependencies(component,system_config)
    assert_equal(6, deps.size)
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(2, d.size, "not enough include paths")
    assert_equal(4, f.size)
  end

  def test_object_dependencies
    system_config=system_configuration_mock
    component=Gaudi::Component.new('FOO',system_config,'mingw')
    component.stubs(:platform).returns('PC')
    component.stubs(:name).returns('FOO')

    deps=object_task_dependencies(component.sources[0],component,system_config)
    assert_equal(6, deps.size)
    assert(deps.include?(component.sources[0]))
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(3, d.size, "not enough include paths")
  end
end