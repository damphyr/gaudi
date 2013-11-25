$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestFilenameOperations < MiniTest::Unit::TestCase
  include Filenames
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
  def test_source_detection
    assert(is_source?('foo.c'), "It's a source file dummy")
    assert(is_source?('foo.src'), "It's a source file dummy")
    assert(is_source?('foo.cpp'), "It's a source file dummy")
    assert(is_source?('foo.cc'), "It's a source file dummy")
    assert(is_source?('foo.asm'), "It's a source file dummy")
    assert(is_source?('foo.Src'), "It's a source file dummy")
  end
end