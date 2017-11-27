require_relative '../../lib/gaudi-c/helpers/components'
require_relative 'helpers'
require "minitest/autorun"
require "mocha/setup"

class TestComponent< Minitest::Test
  attr_reader :src_dir,:system_config
  def setup
    @src_dir=TestHelpers.directory_fixture
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

class TestDeployment< Minitest::Test
  attr_reader :src_dir,:system_config
  def setup
    @src_dir=TestHelpers.directory_fixture
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