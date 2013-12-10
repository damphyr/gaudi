$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"
require 'rake'

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
    system_config.stubs(:to_path).returns('system.cfg')
    system_config
  end

  def test_component_dependencies
    system_config=system_configuration_mock
    program=Gaudi::Component.new('FOO',system_config,'mingw')

    deps=component_task_dependencies(program,system_config)
    assert_equal(3, deps.size)
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(2, d.size)
    assert_equal(1, f.size)
  end

  def test_object_dependencies
    system_config=system_configuration_mock
    component=Gaudi::Component.new('FOO',system_config,'mingw')

    deps=object_task_dependencies(component.sources[0],component,system_config)
    assert_equal(6, deps.size)
    assert(deps.include?(component.sources[0]))
    f,d=deps.partition{|e| !File.directory?(e.to_s)}
    assert_equal(3, d.size, "not enough include paths")
  end
end