require_relative '../../lib/gaudi'
require "minitest/autorun"
require "mocha/setup"


module Gaudi::Configuration::SystemModules::TestLists
  def self.list_keys
    ['platforms','sources']
  end
  def self.path_keys
    ['sources']
  end
  def sources
    @config["sources"].map{|d| File.expand_path(d)}
  end
end

class TestSystemConfiguration < Minitest::Test
  def mock_system_configuration filename,lines
    fname=File.expand_path(File.join(File.dirname(__FILE__),filename))
    File.stubs(:exists?).with(fname).returns(true)
    File.stubs(:readlines).with(fname).returns(lines)
    fname
  end
  def test_list_of_paths
    config=mock_system_configuration('system.cfg',['base=.','out=out/','sources= src,tmp,../out'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    paths=[File.join(File.dirname(config),'src'),File.join(File.dirname(config),'tmp'),File.expand_path(File.join(File.dirname(config),'..','out'))]
    assert_equal(paths,cfg.sources)
  end
end