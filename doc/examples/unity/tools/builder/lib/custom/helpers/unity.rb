require 'delegate'

module Gaudi::Configuration::SystemModules
  #System configuration parameters for the Unity
  #unit testing framework
  module UnityConfiguration
    def self.list_keys
      []
    end

    def self.path_keys
      ['unity_runner_generator']
    end
    #Point this to the Ruby script Unity uses to create test runners
    # unity_runner_generator=path/to/unity/auto/generate_test_runner.rb
    def unity_runner_generator
      return required_path(@config['unity_runner_generator'])
    end
  end
end

module UnityOperations
  include Gaudi::Tasks::Build
  #Task to build Unity tests for a component
  def unity_task component,system_config
    c=UnityTest.new(component,system_config)
    t=program_task(c,system_config)
    file t => test_runner_task(component,system_config)
    return t
  end
  #Creates a file task that creates the test runner for the given component
  def test_runner_task component,system_config
    src= test_runner(component,system_config)
    runner_deps=component.test_files
    runner_deps.delete(src)
    file src => runner_deps do |t|
      puts "Generating test runner for #{component.name}"
      sources=component.test_files.select{|f| is_source?(f)}
      raise GaudiError,"No test sources for #{component.name}" if sources.empty?
      cmdline="ruby #{system_config.unity_runner_generator} #{sources} #{t.name}"
      mkdir_p(File.dirname(t.name),:verbose=>false)
      cmd=Patir::ShellCommand.new(:cmd=>cmdline)
      cmd.run
      if !cmd.success?
        puts [cmd,cmd.output,cmd.error].join("\n")
        raise GaudiError,"Creating test runner for #{component.name} failed"
      end
    end
  end
  #
  def test_runner component,system_config
    if component.test_directories.empty?
      raise GaudiError, "There are no tests for #{component.name}"
    else
      File.join(component.test_directories[0],"#{component.name}Runner.c")
    end
  end
end
#Most awesome way to bend the base class to our whim
class UnityTest < DelegateClass(Gaudi::Component)
  attr_reader :directories,:dependencies,:name
  def initialize component,system_config
    super(component)
    @directories=__getobj__.directories+__getobj__.test_directories
    unity=Gaudi::Component.new('Unity',system_config,platform)
    @dependencies= [unity]+__getobj__.dependencies+unity.dependencies
    @name="#{__getobj__.name}Test"
    @system_config=system_config
  end
  def sources
    __getobj__.sources+__getobj__.test_files.select{|src| is_source?(src)}
  end
  def headers
    __getobj__.headers+__getobj__.test_files.select{|src| is_header?(src)}
  end
  #External (additional) libraries the Program depends on.
  def external_libraries
    @system_config.external_libraries(platform)
  end
  #List of resources to copy with the program artifacts
  def resources
    @system_config.resources(platform)
  end
end
