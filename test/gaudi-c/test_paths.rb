require_relative '../../lib/gaudi-c/helpers/paths'
require "minitest/autorun"
require "mocha/setup"

class TestStandardPaths < Minitest::Test
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
    assert(cmd_file.end_with?('.breadcrumb'), "Not a compiler cmd file.")
    cmd_file=command_file("foo.asm",system_config,component.platform)
    assert(cmd_file.end_with?('.breadcrumb'), "Not a compiler cmd file.")
  end
end