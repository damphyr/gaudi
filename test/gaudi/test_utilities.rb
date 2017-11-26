require_relative '../../lib/gaudi'
require "minitest/autorun"
require "mocha/setup"

class TestUtilities < Minitest::Test
  def test_switch_configuration
    Gaudi::Configuration::SystemConfiguration.stubs(:load).returns([])
    ENV['GAUDI_CONFIG']='./bar.cfg'
    Gaudi::Configuration.switch_configuration('./foo.cfg') do
      assert_equal('./foo.cfg', ENV['GAUDI_CONFIG'])
    end
  end
end