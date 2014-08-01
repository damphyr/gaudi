$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers.rb'
require "minitest/autorun"
require "mocha/setup"
require "rake/file_list"
require "gaudi"

class TestStandardPaths < MiniTest::Unit::TestCase
  include Gaudi::StandardPaths
  def test_filenames
    component=mock()
    system_config=mock()
    component.stubs(:platform).returns('gcc')
    component.stubs(:name).returns('foo')
    component.stubs(:parent).returns(nil)
    system_config.stubs(:out).returns('out')
    system_config.stubs(:extensions).returns(['.o','.a','.e'])

    exe=executable(component,system_config)
    assert(exe.end_with?('.e'), "Not an exe.")
    lib=library(component,system_config)
    assert(lib.end_with?('.a'), "Not a lib.")
    obj=object_file('foo.c',component,system_config)
    assert(obj.end_with?('.o'), "not an object.")
    cmd_file=command_file(exe,system_config,component.platform)
    assert(cmd_file.end_with?('.link'), "Not a linker cmd file.")
    cmd_file=command_file(lib,system_config,'gcc')
    assert(cmd_file.end_with?('.library'), "Not a librarian cmd file.")
    cmd_file=command_file("foo.c",system_config,component.platform)
    assert(cmd_file.end_with?('.compile'), "Not a compiler cmd file.")
    cmd_file=command_file("foo.asm",system_config,component.platform)
    assert(cmd_file.end_with?('.assemble'), "Not a compiler cmd file.")
  end
end

class TestComponent< MiniTest::Unit::TestCase
  attr_reader :src_dir,:system_config
  include TestHelpers
  def setup
    @src_dir=directory_fixture
    @system_config=mock()
    @system_config.expects(:source_directories).returns([src_dir])
    @system_config.stubs(:header_extensions).returns('.h')
  end
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end
  def test_component
    system_config.stubs(:source_extensions).returns('.c,.asm')
    comp=Gaudi::Component.new('FOO',system_config,'mingw')
    assert_equal('FOO', comp.name)
    assert_equal(2, comp.directories.size)
    assert_equal(3, comp.sources.size)
    assert_equal(2, comp.headers.size)
    assert_equal(5, comp.all.size)
    assert_equal(3, comp.test_files.size)
  end

  def test_component_mixed_mode
    system_config.stubs(:source_extensions).returns('.c,.cpp,.asm')
    comp=Gaudi::Component.new('FOO',system_config,'mingw')
    assert_equal('FOO', comp.name)
    assert_equal(2, comp.directories.size)
    assert_equal(5, comp.sources.size)
    assert_equal(2, comp.headers.size)
    assert_equal(7, comp.all.size)
    assert_equal(4, comp.test_files.size)
  end
end

class TestDeployment< MiniTest::Unit::TestCase
  attr_reader :src_dir,:system_config
  include TestHelpers
  def setup
    @src_dir=directory_fixture
    @system_config=mock()
    @system_config.stubs(:source_directories).returns(Rake::FileList[src_dir])
    @system_config.stubs(:header_extensions).returns('.h')
    @system_config.stubs(:source_extensions).returns('.c,.cpp,.asm')
  end
  def teardown
    rm_rf(File.join(File.dirname(__FILE__),'tmp'),:verbose=>false)
  end
  def test_duplicate_program_name
    assert_raises(GaudiError) { Gaudi::Deployment.new('BAR',system_config)}
  end
  def test_deployment
    deployment=Gaudi::Deployment.new("FOO",system_config)
    assert_equal(['foo'], deployment.platforms)
    assert_equal(1, deployment.programs('foo').size)
    pgm=deployment.programs('foo').first
    pgm.dependencies.each do |dep| 
      assert_equal("Pinky", dep.parent.name)
    end
  end
end