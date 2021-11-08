require_relative "../../lib/gaudi"
require "minitest/autorun"
require "mocha/minitest"

class TestLoader < Minitest::Test
  def mock_system_configuration(filename, lines)
    fname = File.expand_path(File.join(File.dirname(__FILE__), filename))
    File.stubs(:exist?).with(fname).returns(true)
    File.stubs(:readlines).with(fname).returns(lines)
    fname
  end

  def test_empty_configuration
    config = mock_system_configuration("system.cfg", [])
    cfg = Gaudi::Configuration::Loader.new(config)
    assert_equal([config], cfg.configuration_files)
  end

  def test_syntax_error
    config = mock_system_configuration("system.cfg", ["foo"])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::Loader.new(config) }
  end

  def test_comments
    config = mock_system_configuration("system.cfg", ["", "#comment"])
    cfg = Gaudi::Configuration::Loader.new(config)
    assert(cfg.config.empty?, "Configuration should be empty")
  end

  def test_import
    config = mock_system_configuration("system.cfg", ["import import.cfg"])
    File.expects(:exist?).with(File.join(File.dirname(config), "import.cfg")).returns(true).times(2)
    File.expects(:readlines).with(File.join(File.dirname(config), "import.cfg")).returns(["foo=bar"])
    cfg = Gaudi::Configuration::Loader.new(config)
    assert(!cfg.config.empty?, "Configuration should not be empty")
    assert_equal("bar", cfg.config["foo"])
  end

  def test_property_reference
    config = mock_system_configuration("system.cfg", ["foo=bar", "bar=%{foo}"])
    cfg = Gaudi::Configuration::Loader.new(config)
    assert(!cfg.config.empty?, "Configuration should not be empty")
    assert_equal("bar", cfg.config["foo"])
  end

  def test_property_self_reference
    config = mock_system_configuration("system.cfg", ["foo=bar", "foo=%{foo}*%{foo}"])
    cfg = Gaudi::Configuration::Loader.new(config)
    assert(!cfg.config.empty?, "Configuration should not be empty")
    assert_equal("bar*bar", cfg.config["foo"])
  end

  def test_environment
    config = mock_system_configuration("system.cfg", ["setenv GAUDI = brilliant builder"])
    Gaudi::Configuration::Loader.new(config)
    assert_equal("brilliant builder", ENV["GAUDI"])
  end
end
