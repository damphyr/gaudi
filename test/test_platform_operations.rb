$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestPlatformOperations < MiniTest::Unit::TestCase
  include Gaudi::PlatformOperations
  def test_extensions
    ext_obj,ext_lib,ext_exe=*extensions('PC')
    assert_equal('.exe', ext_exe)
    assert_equal('.obj', ext_obj)
    assert_equal('.lib', ext_lib)
    assert_raises(GaudiError) { extensions('FOO') }
  end
  def test_source_detection
    assert(is_source?('foo.c'), "It's a source file dummy")
    assert(is_source?('foo.src'), "It's a source file dummy")
    assert(is_source?('foo.cpp'), "It's a source file dummy")
    assert(is_source?('foo.cc'), "It's a source file dummy")
    assert(is_source?('foo.asm'), "It's a source file dummy")
    assert(is_source?('foo.Src'), "It's a source file dummy")
    assert(!is_source?('foo.foo'), "Definitely not a source file this time")
  end
end