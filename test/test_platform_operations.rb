$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

module TestHelpers
  def mock_configuration lines
    File.expects(:exists?).returns(true)
    File.expects(:readlines).returns(lines)
    File.join(File.dirname(__FILE__),'system.cfg')
  end
end

class TestPlatformOperations < MiniTest::Unit::TestCase
  include PlatformOperations
  def test_extensions
    ext_obj,ext_lib,ext_exe=*extensions('PC')
    assert_equal('.exe', ext_exe)
    assert_equal('.obj', ext_obj)
    assert_equal('.lib', ext_lib)
    assert_raises(GaudiError) { extensions('FOO') }
  end
end