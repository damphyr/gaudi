require_relative "helpers"
require_relative "../../lib/gaudi"
require "minitest/autorun"
require "mocha/minitest"

class TestUtilities < Minitest::Test
  include TestHelpers

  def test_switch_platform_configuration
    File.stubs(:exist?).returns(true)

    mock_config = File.expand_path("system.cfg")
    File.stubs(:readlines).with(mock_config).returns(TestHelpers.system_config_test_data)

    mock_foo = File.expand_path("foo.cfg")
    mock_bar = File.expand_path("bar.cfg")
    File.expects(:readlines).with(mock_bar).returns(TestHelpers.platform_config_test_data + ["foo=bar"])
    File.expects(:readlines).with(mock_foo).returns(TestHelpers.platform_config_test_data)

    system_config = Gaudi::Configuration::SystemConfiguration.new(mock_config)
    Gaudi::Configuration.switch_platform_configuration "./bar.cfg", system_config, "foo" do
      assert_equal("bar", system_config.platform_config("foo")["foo"])
    end
    assert_nil(system_config.platform_config("foo")["foo"])
  end
end
