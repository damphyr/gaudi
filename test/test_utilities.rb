$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestUtilities < MiniTest::Unit::TestCase
  def test_switch_configuration
    Gaudi::Configuration::SystemConfiguration.stubs(:load).returns([])
    ENV['GAUDI_CONFIG']='./bar.cfg'
    switch_configuration('./foo.cfg') do
      assert_equal('./foo.cfg', ENV['GAUDI_CONFIG'])
    end
  end
  def test_switch_platform_configuration
    config=mock()
    config.expects(:platform_config).returns({'foo'=>'bar'})
    config.expects(:read_configuration).returns({'bar'=>'foo'})
    config.expects(:set_platform_config).times(2)
    switch_platform_configuration './foo.cfg',config,'pc' do
      #what exactly are we testing here?
    end
  end
end