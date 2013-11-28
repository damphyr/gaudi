$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers.rb'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestStandardPaths < MiniTest::Unit::TestCase
  include Gaudi::StandardPaths
  def test_filenames
    component=mock()
    system_config=mock()
    component.stubs(:platform).returns('PC')
    component.stubs(:name).returns('foo')
    system_config.stubs(:out).returns('out')
    exe=executable(component,system_config)
    assert(exe.end_with?('.exe'), "Not an exe.")
    obj=object_file('foo.c',component,system_config)
    assert(obj.end_with?('obj'), "not an object.")
  end
end

class TestCCompilationUnit < MiniTest::Unit::TestCase
  include TestHelpers
  include Gaudi::StandardPaths
  include Gaudi::CompilationUnit::C
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end

  def test_determines
    dirs=determine_directories('FOO',[directory_fixture],'mingw')
    assert_equal(2, dirs.size)
    srcs=determine_sources(dirs)
    assert_equal(3, srcs.size)
    hdrs=determine_headers(dirs)
    assert_equal(2,hdrs.size)
    iface=determine_interface_paths(dirs)
    assert_equal(1, iface.size)
    assert_equal(1, determine_test_directories(dirs).size)
  end
end

class TestCPPCompilationUnit < MiniTest::Unit::TestCase
  include TestHelpers
  include Gaudi::StandardPaths
  include Gaudi::CompilationUnit::CPP
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end

  def test_determines
    dirs=determine_directories('FOO',[directory_fixture],'mingw')
    assert_equal(2, dirs.size)
    srcs=determine_sources(dirs)
    assert_equal(3, srcs.size)
    hdrs=determine_headers(dirs)
    assert_equal(2,hdrs.size)
    iface=determine_interface_paths(dirs)
    assert_equal(1, iface.size)
    assert_equal(1, determine_test_directories(dirs).size)
  end
end

class TestComponent< MiniTest::Unit::TestCase
  include TestHelpers
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end
  def test_component
    system_config=mock()
    src_dir=directory_fixture
    system_config.expects(:source_directories).returns([src_dir])
    system_config.expects(:default_compiler_mode).returns('C')
    comp=Gaudi::Component.new('FOO',system_config,'mingw')
    assert_equal('FOO', comp.name)
    assert_equal(2, comp.directories.size)
    assert_equal(3, comp.sources.size)
    assert_equal(2, comp.headers.size)
    assert_equal(5, comp.all.size)
  end
end