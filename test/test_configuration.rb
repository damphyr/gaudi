$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers.rb'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

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
    File.expects(:readlines).with(File.join(File.dirname(config),"import.cfg")).returns(['foo=bar'])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert(!cfg.config.empty?, "Configuration should not be empty")
    assert_equal('bar', cfg.config['foo'])
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
  def test_list_of_paths
    config=mock_configuration('system.cfg',['base=.','out=out/','sources= src,tmp,../out'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    paths=[File.join(File.dirname(config),'src'),File.join(File.dirname(config),'tmp'),File.expand_path(File.join(File.dirname(config),'..','out'))]
    assert_equal(paths,cfg.sources)
  end

  def test_settings
    config=mock_configuration('system.cfg',['base=.','out=out/','sources= src'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal('C', cfg.default_compiler_mode)
    config=mock_configuration('system.cfg',['base=.','out=out/','sources= src','default_compiler_mode=CPP'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal('CPP', cfg.default_compiler_mode)
    config=mock_configuration('system.cfg',['base=.','out=out/','sources= src','default_compiler_mode=FOO'])
    assert_raises(GaudiConfigurationError) {  Gaudi::Configuration::SystemConfiguration.new(config).default_compiler_mode }
  end

  def test_external_libraries
    config=mock_configuration('system.cfg',['base=.','out=out/','platforms=foo','foo=./foo.cfg'])
    platform_cfg=File.join(File.dirname(__FILE__),'foo.cfg')
    File.expects(:exists?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(['libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(__FILE__),'libs.yml')
    File.expects(:exists?).with(lib_yml).returns(true)
    File.expects(:read).with(lib_yml).returns(YAML.dump({'foo'=>'foo.lib'}))
    File.expects(:exists?).with(File.join(File.dirname(__FILE__),'foo.lib')).returns(false)

    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(['foo.lib'], cfg.external_libraries('foo'))
  end

  def test_external_libraries_missing_lib_cfg
    config=mock_configuration('system.cfg',['base=.','out=out/','platforms=foo','foo=./foo.cfg'])
    platform_cfg=File.join(File.dirname(__FILE__),'foo.cfg')
    File.expects(:exists?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(['libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(__FILE__),'libs.yml')
    File.expects(:exists?).with(lib_yml).returns(false)
    
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_raises(GaudiConfigurationError){cfg.external_libraries('foo')}
  end

  def test_external_libraries_missing_token
    config=mock_configuration('system.cfg',['base=.','out=out/','platforms=foo','foo=./foo.cfg'])
    platform_cfg=File.join(File.dirname(__FILE__),'foo.cfg')
    File.expects(:exists?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(['libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(__FILE__),'libs.yml')
    File.expects(:exists?).with(lib_yml).returns(true)
    File.expects(:read).with(lib_yml).returns(YAML.dump({'bar'=>'bar.lib'}))
    
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_raises(GaudiConfigurationError){cfg.external_libraries('foo')}
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
    system_cfg=mock('system')
    system_cfg.stubs(:config_base).returns(File.dirname(__FILE__))
    config=mock_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo,bar','compiler_options= FOO BAR'])
    
    cfg=Gaudi::Configuration::BuildConfiguration.new(config)
    assert_equal('TST', cfg.prefix)
    assert_equal(['COD','MOD'],cfg.deps)
    assert_equal(["#{File.dirname(__FILE__)}/inc"],cfg.incs)
    assert_equal('FOO BAR', cfg.compiler_options)

    system_cfg.expects(:external_libraries_config).returns({'foo'=>'foo.lib','bar'=>'bar.lib'})
    File.expects(:exists?).with(File.join(File.dirname(__FILE__),'foo.lib')).returns(false)
    File.expects(:exists?).with(File.join(File.dirname(__FILE__),'bar.lib')).returns(false)
    assert_equal(['foo.lib','bar.lib'],cfg.libs(system_cfg,'pc'))
  end

  def test_load
    config=mock_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo.lib,bar.lib'])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::BuildConfiguration.load([])}
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
    assert_equal('TST',cfg.prefix)
  end

  def test_compiler_mode
    config=mock_configuration('build.cfg',['prefix=TST','compiler_mode=C'])
    system_config=mock()
    system_config.stubs(:default_compiler_mode).returns('C')
    cfg=Gaudi::Configuration::BuildConfiguration.new(config)
    assert_equal(Gaudi::CompilationUnit::C, cfg.compiler_mode(system_config))
    config=mock_configuration('build.cfg',['prefix=TST','compiler_mode=Cpp'])
    cfg=Gaudi::Configuration::BuildConfiguration.new(config)
    assert_equal(Gaudi::CompilationUnit::CPP, cfg.compiler_mode(system_config))
    config=mock_configuration('build.cfg',['prefix=TST','compiler_mode=foo'])
    assert_raises(GaudiConfigurationError){Gaudi::Configuration::BuildConfiguration.new(config).compiler_mode(system_config)}
  end
end