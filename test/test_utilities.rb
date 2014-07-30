$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestUtilities < MiniTest::Unit::TestCase
  include TestHelpers
  def test_switch_configuration
    Gaudi::Configuration::SystemConfiguration.stubs(:load).returns([])
    ENV['GAUDI_CONFIG']='./bar.cfg'
    Gaudi::Configuration.switch_configuration('./foo.cfg') do
      assert_equal('./foo.cfg', ENV['GAUDI_CONFIG'])
    end
  end
  def test_switch_platform_configuration
    File.stubs(:exists?).returns(true)
    File.expects(:readlines).returns(platform_config_test_data+['foo=bar'])
    File.expects(:readlines).returns(platform_config_test_data)
    File.expects(:readlines).returns(system_config_test_data)
    config=Gaudi::Configuration::SystemConfiguration.new('bar.cfg')
    Gaudi::Configuration.switch_platform_configuration './foo.cfg',config,'foo' do
      assert_equal('bar', config.platform_config('foo')['foo'])
    end
    assert_nil(config.platform_config('foo')['foo'])
  end
end