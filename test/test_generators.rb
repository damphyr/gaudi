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
    system_config.stubs(:source_directories).returns(FileList[File.join(File.dirname(__FILE__),'tmp')])
    system_config.stubs(:out).returns('out')
    system_config.stubs(:to_path).returns('system.cfg')
    system_config.stubs(:source_extensions).returns('.c')
    system_config.stubs(:header_extensions).returns(['.h'])
    system_config.stubs(:configuration_files).returns(['system.cfg'])
    system_config
  end

  def test_component_dependencies
    system_config=system_configuration_mock
    component=Gaudi::Component.new('FOO',system_config,'mingw')
    deps=component_task_dependencies(component,system_config)
    assert_equal(4, deps.size)
  end

  def test_object_dependencies
    system_config=system_configuration_mock
    system_config.stubs(:extensions).returns(['.o','.a','.e'])
    component=Gaudi::Component.new('FOO',system_config,'mingw')
    deps=object_task_dependencies(component.sources.first,component,system_config)
    assert_equal(5, deps.size)
    assert(deps.include?(component.sources.first))
  end

  def test_deployment_task
    system_config=Gaudi::Configuration::SystemConfiguration.new("#{File.dirname(__FILE__)}/tmp/brain.cfg")
    deployment=Gaudi::Deployment.new('FOO',system_config)
    assert(deployment_task(deployment,system_config))
  end
end
class TestRuleGenerators < MiniTest::Unit::TestCase
  include TestHelpers
  include Rake::DSL
  include Gaudi::Tasks::Build
  include Gaudi::Rules::Build
  

  def one_rule_mock
    platform_config=mock()
    platform_config.expects(:extensions).returns([".o",".a",".elf"])
    system_config=mock()
    system_config.expects(:platform_config).returns(platform_config)
    system_config
  end

  def all_rules_mock
    platform_config=mock()
    platform_config.expects(:extensions).returns([".o",".a",".elf"]).times(4)
    system_config=mock()
    system_config.expects(:platform_config).returns(platform_config).times(4)
    system_config.stubs(:platforms).returns(["foo","bar"])
    system_config
  end

  def test_object_rule
    system_config=one_rule_mock
    assert(object_rule(system_config,"foo"))
  end

  def test_executable_rule
    system_config=one_rule_mock
    assert(executable_rule(system_config,"foo"))
  end

  def test_all_rules
    system_config=all_rules_mock
    assert(all_rules(system_config))
  end
end