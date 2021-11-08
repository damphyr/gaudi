require_relative "../../lib/gaudi"
require "minitest/autorun"
require "mocha/minitest"

class TestSystemConfiguration < Minitest::Test
  def mock_system_configuration(filename, lines)
    fname = File.expand_path(File.join(File.dirname(__FILE__), filename))
    File.stubs(:exist?).with(fname).returns(true)
    File.stubs(:readlines).with(fname).returns(lines)
    fname
  end

  def test_empty_configuration
    config = mock_system_configuration("system.cfg", [])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::SystemConfiguration.new(config) }
  end

  def test_basic_configuration
    config = mock_system_configuration("system.cfg", ["base=.", "out=out/"])
    cfg = Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(File.expand_path(File.dirname(__FILE__)), cfg.base_dir)
    assert_equal(File.expand_path(File.join(File.dirname(__FILE__), "out")), cfg.out_dir)
    assert_equal(cfg.gaudi_modules, [], "Module list includes stuff")
  end

  def test_load
    config = mock_system_configuration("system.cfg", ["base=.", "out=out/"])
    cfg = Gaudi::Configuration::SystemConfiguration.load([config])
    assert_equal(File.expand_path(File.dirname(__FILE__)), cfg.base)
  end
end
