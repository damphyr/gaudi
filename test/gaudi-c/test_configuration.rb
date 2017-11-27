require_relative '../../lib/gaudi'
require_relative '../../lib/gaudi-c/helpers/configuration'
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"

class TestSystemConfiguration < Minitest::Test

  def test_platforms
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data+['bar=foo'])
    cfg=Gaudi::Configuration::SystemConfiguration.load([config])  
    assert_equal(['foo'], cfg.platforms)
    assert_equal({"source_directories"=>"common,foo","source_extensions"=>".c,.cpp", "header_extensions"=>".h",
        "object_extension"=>".o", "library_extension"=>".so", "executable_extension"=>".e","libs"=>"", "lib_cfg"=>"libs.yml","bar"=>"foo",
        'compiler_options'=>'-c','assembler_options'=>'-a','library_options'=>'-l','linker_options'=>'-e'}, cfg.platform_config('foo'))
  end
  
  def test_external_libraries
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data+['libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(config),'libs.yml')
    File.expects(:exist?).with(lib_yml).returns(true)
    File.expects(:read).with(lib_yml).returns(YAML.dump({'foo'=>'foo.lib'}))
    File.expects(:exist?).with(File.expand_path(File.join(File.dirname(__FILE__),'foo.lib'))).returns(false)

    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(['foo.lib'], cfg.external_libraries('foo'))
  end

  def test_external_libraries_missing_lib_cfg
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(['source_extensions=.c,.cpp','header_extensions=.h',
      'object_extension=.o', 'library_extension=.so','executable_extension=','libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(config),'libs.yml')
    File.expects(:exist?).with(lib_yml).returns(false)
    
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_raises(GaudiConfigurationError){cfg.external_libraries('foo')}
  end

  def test_external_libraries_missing_token
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data+[
      'libs=foo','lib_cfg=libs.yml'])
    lib_yml=File.join(File.dirname(config),'libs.yml')
    File.expects(:exist?).with(lib_yml).returns(true)
    File.expects(:read).with(lib_yml).returns(YAML.dump({'bar'=>'bar.lib'}))
    
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_raises(GaudiConfigurationError){cfg.external_libraries('foo')}
  end

  def test_external_includes
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data+['incs=./foo,./bar'])

    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(["#{File.dirname(config)}/foo", "#{File.dirname(config)}/bar"],cfg.external_includes('foo'))
  end
  def test_external_includes_empty
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data)
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert(cfg.external_includes('foo').empty?)
  end

  def test_extensions
    config=TestHelpers.mock_system_configuration('system.cfg',TestHelpers.system_config_test_data)
    platform_cfg=File.join(File.dirname(config),'foo.cfg')
    File.expects(:exist?).with(platform_cfg).returns(true)
    File.expects(:readlines).with(platform_cfg).returns(TestHelpers.platform_config_test_data)
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal([".o", ".so", ".e"], cfg.extensions('foo'))
  end
end

class TestBuildConfiguration < Minitest::Test
  def test_empty_configuration
    config=TestHelpers.mock_system_configuration('build.cfg',[])
    assert_raises(GaudiConfigurationError) {  Gaudi::Configuration::BuildConfiguration.load([config]) }
  end

  def test_basic_configuration
    system_cfg=mock('system')
    system_cfg.stubs(:config_base).returns(File.dirname(__FILE__))
    config=TestHelpers.mock_system_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo,bar','compiler_options= FOO BAR'])
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
    assert_equal('TST', cfg.prefix)
    assert_equal(['COD','MOD'],cfg.deps)
    assert_equal(["#{File.expand_path(File.dirname(__FILE__))}/inc"],cfg.incs)
    assert_equal('FOO BAR', cfg.option('compiler_options'))

    system_cfg.expects(:external_libraries_config).returns({'foo'=>'foo.lib','bar'=>'bar.lib'})
    File.expects(:exist?).with(File.expand_path(File.join(File.dirname(__FILE__),'foo.lib'))).returns(false)
    File.expects(:exist?).with(File.expand_path(File.join(File.dirname(__FILE__),'bar.lib'))).returns(false)
    assert_equal(['foo.lib','bar.lib'],cfg.libs(system_cfg,'gcc'))
  end
  
  def test_append_to_list_param
    system_cfg=mock('system')
    system_cfg.stubs(:config_base).returns(File.dirname(__FILE__))
    config=TestHelpers.mock_system_configuration('build.cfg',['prefix=TST','deps=COD,MOD', 'deps+=ABC', 'deps+=COD,DEF','incs= ./inc','libs= foo,bar','compiler_options= FOO BAR'])
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
    assert_equal('TST', cfg.prefix)
    assert_equal(['COD','MOD', 'ABC', 'DEF'],cfg.deps)
    assert_equal(["#{File.expand_path(File.dirname(__FILE__))}/inc"],cfg.incs)
    assert_equal('FOO BAR', cfg.option('compiler_options'))

    system_cfg.expects(:external_libraries_config).returns({'foo'=>'foo.lib','bar'=>'bar.lib'})
    File.expects(:exist?).with(File.expand_path(File.join(File.dirname(__FILE__),'foo.lib'))).returns(false)
    File.expects(:exist?).with(File.expand_path(File.join(File.dirname(__FILE__),'bar.lib'))).returns(false)
    assert_equal(['foo.lib','bar.lib'],cfg.libs(system_cfg,'gcc'))
  end

  def test_property_reference
    config=TestHelpers.mock_system_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','compiler_options= -DMODULE=%{prefix}'])
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
    assert_equal('-DMODULE=TST',cfg.option('compiler_options'))
  end
  
  def test_load
    config=TestHelpers.mock_system_configuration('build.cfg',['prefix=TST','deps=COD,MOD','incs= ./inc','libs= foo.lib,bar.lib'])
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::BuildConfiguration.load([])}
    cfg=Gaudi::Configuration::BuildConfiguration.load([config])
    assert_equal('TST',cfg.prefix)
  end
end

class TestPlatformConfiguration < Minitest::Test

  def setup
    TestHelpers.directory_fixture
  end
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end

  def test_platform_config
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::PlatformConfiguration.new 'foo',{'bar'=>'bla'} }
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::PlatformConfiguration.new 'foo',{'source_extensions'=>'bla'} }
    assert_raises(GaudiConfigurationError) { Gaudi::Configuration::PlatformConfiguration.new 'foo',{'header_extensions'=>'bla'} }
    pcfg=Gaudi::Configuration::PlatformConfiguration.new 'foo',{'source_extensions'=>'.c','header_extensions'=>'.h',
      'object_extension'=>'.o', 'library_extension'=>'.so','executable_extension'=>'.e'}
    assert_equal('.c',pcfg['source_extensions'])
    assert_equal('.h', pcfg['header_extensions'])
    assert_equal([".o", ".so", ".e"], pcfg.extensions)
  end

  def test_platform_extend
    system_config=Gaudi::Configuration::SystemConfiguration.new(File.join(File.dirname(__FILE__),'tmp/brain.cfg'))
    component=mock
    component.stubs(:platform).returns('foo')
    component_config=mock
    component_config.stubs(:option).returns('-o')
    component.stubs(:configuration).returns(component_config)
    
    assert_equal('-c', system_config.platform_config('foo')['compiler_options'])
    assert_equal('-a', system_config.platform_config('foo')['assembler_options'])
    assert_equal('-l', system_config.platform_config('foo')['library_options'])
    assert_equal('-e', system_config.platform_config('foo')['linker_options'])

    Gaudi::Configuration::PlatformConfiguration.extend(component,system_config) do
      assert_equal('-c -o', system_config.platform_config('foo')['compiler_options'])
      assert_equal('-a -o', system_config.platform_config('foo')['assembler_options'])
      assert_equal('-l -o', system_config.platform_config('foo')['library_options'])
      assert_equal('-e -o', system_config.platform_config('foo')['linker_options'])
    end
    
    assert_equal('-c', system_config.platform_config('foo')['compiler_options'])
    assert_equal('-a', system_config.platform_config('foo')['assembler_options'])
    assert_equal('-l', system_config.platform_config('foo')['library_options'])
    assert_equal('-e', system_config.platform_config('foo')['linker_options'])
  end
end