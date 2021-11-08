require_relative "../../lib/gaudi"
require "minitest/autorun"
require "mocha/minitest"

class TestUtilities < Minitest::Test
  include Gaudi::Utilities

  def test_env_setup
    File.stubs(:exist?).with(Gaudi::DEFAULT_CONFIGURATION_FILE).returns(true)
    File.stubs(:readlines).with(Gaudi::DEFAULT_CONFIGURATION_FILE).returns(["base=.", "out=./out"])
    cfg = Gaudi.env_setup(File.dirname(__FILE__))
    assert_equal(cfg, $configuration)
  end

  def test_switch_configuration
    Gaudi::Configuration::SystemConfiguration.stubs(:load).returns([])
    ENV["GAUDI_CONFIG"] = "./bar.cfg"
    Gaudi::Configuration.switch_configuration("./foo.cfg") do
      assert_equal("./foo.cfg", ENV["GAUDI_CONFIG"])
    end
  end
end
