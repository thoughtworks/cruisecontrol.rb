require File.dirname(__FILE__) + '/../test_helper'
require 'builder_starter'
require 'project'

class BuilderStarterTest < Test::Unit::TestCase
  include FileSandbox
  
  def setup
    @svn = FakeSourceControl.new("bob")
    @one = Project.new("one", @svn)
    @two = Project.new("two", @svn)
  end
  
  def test_start_builders_should_begin_builder_for_each_project
    Projects.expects(:load_all).returns([@one, @two])
    
    BuilderStarter.expects(:begin_builder).with(@one.name)
    BuilderStarter.expects(:begin_builder).with(@two.name)
    
    BuilderStarter.start_builders
  end
  
  def test_should_use_platform_specific_executable
    Platform.expects(:family).returns("mswin32")
    Platform.expects(:create_child_process).with(@one.name, "\"#{RAILS_ROOT}/cruise.cmd\" build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)

    Platform.expects(:family).returns("linux")
    Platform.expects(:create_child_process).with(@one.name, "\"#{RAILS_ROOT}/cruise\" build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)
  end

  def test_should_invoke_cruise_in_verbose_mode
    $VERBOSE_MODE = true
    begin
      Platform.expects(:family).returns("mswin32")
      Platform.expects(:create_child_process).with(@one.name, "\"#{RAILS_ROOT}/cruise.cmd\" build #{@one.name} --trace")
      BuilderStarter.begin_builder(@one.name)

      Platform.expects(:family).returns("linux")
      Platform.expects(:create_child_process).with(@one.name, "\"#{RAILS_ROOT}/cruise\" build #{@one.name} --trace")
      BuilderStarter.begin_builder(@one.name)
    ensure
      $VERBOSE_MODE = false
    end
  end

end
