require 'delegate'

module Gaudi::Configuration::SystemModules
  #System configuration parameters for the Unity unit testing framework
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
  #System configuration parameters for the CMock mocking framework
  module CMockConfiguration
    def self.list_keys
      []
    end

    def self.path_keys
      ['cmock_path']
    end
    #Point this to the directory containing the CMock release
    def cmock_path
      return required_path(@config['cmock_path'])
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
  #Returns the file name for the component's test runner
  def test_runner component,system_config
    if component.test_directories.empty?
      raise GaudiError, "There are no tests for #{component.name}"
    else
      File.join(component.test_directories[0],"#{component.name}Runner.c")
    end
  end
end

module CMockOperations
  CMOCK_CONFIG={:plugins=>[:callback, :ignore]}
  #adapt the CMock configuration for the given component
  def cmock_config component,system_config
    cmock_config=CMOCK_CONFIG
    cmock_config[:mock_path]=File.join(system_config.out,component.platform,'mocks')
    return cmock_config
  end
  #Returns a task that generates a CMock for the given header
  def cmock_task source_header,component,system_config
    require "#{system_config.cmock_path}/lib/cmock"
    mock_header=cmock_header(source_header,component,system_config)
    unless Rake::Task.task_defined?(mock_header)
      file mock_header => [source_header] do |t|
        mkdir_p(File.dirname(mock_header),:verbose=>false)
        CMock.new(cmock_config(component,system_config)).setup_mocks([source_header])
      end#file
    end
  end
  #Returns the cmock implementation files corresponding to the mocks for the given component
  def cmock_sources component,system_config
    cmock_headers(component,system_config).map{|h| h.pathmap("%X.c")}
  end
  def cmock_includes component,system_config
    [File.join(system_config.out,component.platform,'mocks')]
  end
  private
  #Returns an Array with all the CMock header tasks for the given component
  def generate_mock_tasks component,system_config
    puts "Generating mocks for #{component.name}"
    headers=headers_to_mock(component,system_config)
    headers.map{|h| cmock_task(h,component,system_config)}
  end
  #Parses the component tests for includes that start with Mock
  #and determines which component headers need to be mocked
  #
  #Returns a list of the component headers that require mocks
  def headers_to_mock component,system_config
    headers=FileList.new
    test_list=component.test_files.select{|f| is_source?(f)}
    #remove possible remnants from previous generations
    test_list.select!{|f| /Mock*/!~f }
    test_list.select!{|f| /Runner\.c/!~f }
    test_list.each do |test_source|
      line_no=0
      begin
        src_lines=File.readlines(test_source)
        src_lines.each_with_index do |line,idx|
          line_no=idx+1
          if /\A\s*#include\s*"Mock(.*\.h)"/=~line
            header_file=$1
            headers+=FileList[*component.include_paths.pathmap("%p/#{header_file}")].existing
          end  
        end
      rescue
        raise $!, "While processing #{test_source}:#{line_no}: #{$!}", $!.backtrace
      end
    end
    return headers.uniq
  end
  #Returns the filename for the mock header to generate
  def cmock_header source_header,component,system_config
    File.join( cmock_config(component,system_config)[:mock_path],"Mock#{File.basename(source_header)}")
  end
  def cmock_headers component,system_config
    headers_to_mock(component,system_config).map{|h| cmock_header(h,component,system_config)}
  end
end

module UnitTestOperations
  include CMockOperations
  include UnityOperations
  def unit_test_task component,system_config
    generate_test_files(component,system_config)
    mkdir_p(File.join(system_config.out,component.platform,'mocks'))
    puts "Generating Unit Test task"
    c=UnitTest.new(component,system_config)
    t=program_task(c,system_config) 
    return t
  end
  def generate_test_files component,system_config
    mock_tasks=generate_mock_tasks(component,system_config)
    test_runner_task=test_runner_task(component,system_config)
    file test_runner_task=>mock_tasks
    Rake::Task[test_runner_task].invoke
  end
end

class UnitTest < DelegateClass(Gaudi::Program)
  include UnitTestOperations
  attr_reader :directories,:dependencies,:name
  def initialize component,system_config
    @parent=self
    super(component)
    @directories=__getobj__.directories+__getobj__.test_directories
    unity=Gaudi::Component.new('Unity',system_config,platform)
    cmock=Gaudi::Component.new('CMock',system_config,platform)
    @dependencies= [unity,cmock]+unity.dependencies+cmock.dependencies
    @name="#{__getobj__.name}Test"
    @system_config=system_config
  end
  def sources
    __getobj__.sources+__getobj__.test_files.select{|src| is_source?(src)}+cmock_sources(self,@system_config)
  end
  def headers
    __getobj__.headers+__getobj__.test_files.select{|src| is_header?(src)}
  end
  def include_paths
    incs=__getobj__.include_paths+cmock_includes(self,@system_config)
    dependencies.each{|dep| incs+=dep.interface_paths}
    incs.uniq
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