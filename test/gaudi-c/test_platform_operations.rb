require_relative "helpers"
require_relative "../../lib/gaudi-c/helpers/operations"
require "minitest/autorun"
require "mocha/minitest"

class TestPlatformOperations < Minitest::Test
  include Gaudi::PlatformOperations

  def test_source_detection
    assert(is_source?("foo.c"), "It's a source file dummy")
    assert(is_source?("foo.src"), "It's a source file dummy")
    assert(is_source?("foo.cpp"), "It's a source file dummy")
    assert(is_source?("foo.cc"), "It's a source file dummy")
    assert(is_source?("foo.asm"), "It's a source file dummy")
    assert(is_source?("foo.Src"), "It's a source file dummy")
    assert(!is_source?("foo.foo"), "Definitely not a source file this time")
  end
end
