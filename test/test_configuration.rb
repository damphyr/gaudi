$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"
require_relative 'helpers.rb'

class TestLoader < MiniTest::Unit::TestCase
  include TestHelpers
  def test_empty_configuration
    config=mock_configuration('system.cfg',[])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert_equal(config, cfg.config_file)
  end
  def test_syntax_error
    config=mock_configuration('system.cfg',['foo'])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::Loader.new(config) }
  end
  def test_comments
    config=mock_configuration('system.cfg',['','#comment'])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert(cfg.config.empty?, "Configuration should be empty")
  end
  def test_import
    config=mock_configuration('system.cfg',['import import.cfg'])
    File.expects(:exists?).with(File.join(File.dirname(config),"import.cfg")).returns(true).times(2)
    File.expects(:readlines).with(File.join(File.dirname(config),"import.cfg")).returns([])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert(cfg.config.empty?, "Configuration should be empty")
  end
  def test_environment
    config=mock_configuration('system.cfg',['setenv GAUDI = brilliant builder'])
    Gaudi::Configuration::Loader.new(config)
    assert_equal('brilliant builder',ENV['GAUDI'])
  end
end

class TestSystemConfiguration < MiniTest::Unit::TestCase
  include TestHelpers
  def test_empty_configuration
    config=mock_configuration('system.cfg',[])
    assert_raises(GaudiConfigurationError) {  Gaudi::Configuration::SystemConfiguration.new(config)}
  end

  def test_basic_configuration
    config=mock_configuration('system.cfg',['base=.','out=out/'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(File.dirname(__FILE__), cfg.base_dir)
    assert_equal(File.join(File.dirname(__FILE__),'out'), cfg.out_dir)
  end

  def test_load
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::SystemConfiguration.load([])}
    config=mock_configuration('system.cfg',['base=.','out=out/'])
    cfg=Gaudi::Configuration::SystemConfiguration.load([config])
    assert_equal(File.dirname(__FILE__),cfg.base)
  end
  def test_platforms
    config=mock_configuration('system.cfg',['base=.','out=out/','platforms=foo','foo=./foo.cfg'])
    platform_cfg=File.join(File.dirname(__FILE__),'foo.cfg')
    File.expects(:exists?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(['bar=foo'])
    cfg=Gaudi::Configuration::SystemConfiguration.load([config])
    assert_equal(['foo'], cfg.platforms)
    assert_equal({"bar"=>"foo"}, cfg.platform_config('foo'))
  end
end

class TestBuildConfiguration < MiniTest::Unit::TestCase
  include TestHelpers
  def test_empty_configuration
    config=mock_configuration('build.cfg',[])
    cfg=Gaudi::Configuration::BuildConfiguration.new(config)
    assert(cfg.respond_to?(:prefix), "prefix should be defined.")
  end

  def test_basic_configuration
    config=mock_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo.lib,bar.lib','options= FOO BAR'])
    cfg=Gaudi::Configuration::BuildConfiguration.new(config)
    assert_equal('TST', cfg.prefix)
    assert_equal(['COD','MOD'],cfg.deps)
    assert_equal(['./inc'],cfg.incs)
    assert_equal(['foo.lib','bar.lib'],cfg.libs)
    assert_equal('FOO BAR', cfg.options)
  end

  def test_load
    config=mock_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo.lib,bar.lib'])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::BuildConfiguration.load([])}
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
  end
end
