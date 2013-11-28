$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

class TestFilenameOperations < MiniTest::Unit::TestCase
  include Gaudi::Filenames
  def test_source_detection
    assert(is_source?('foo.c'), "It's a source file dummy")
    assert(is_source?('foo.src'), "It's a source file dummy")
    assert(is_source?('foo.cpp'), "It's a source file dummy")
    assert(is_source?('foo.cc'), "It's a source file dummy")
    assert(is_source?('foo.asm'), "It's a source file dummy")
    assert(is_source?('foo.Src'), "It's a source file dummy")
  end
end