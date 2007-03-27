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
    
    BuilderStarter.expects(:begin_builder).with(@one.name, false)
    BuilderStarter.expects(:begin_builder).with(@two.name, false)
    
    BuilderStarter.start_builders
  end
  
  def test_should_be_able_to_start_builders_in_verbose_mode
    Projects.expects(:load_all).returns([@one, @two])
    BuilderStarter.expects(:begin_builder).with(@one.name, true)
    BuilderStarter.expects(:begin_builder).with(@two.name, true)
    BuilderStarter.start_builders true    
  end
  
  def test_should_invoke_cruise_in_verbose_mode
    Thread.expects(:new).with(@one.name).yields(@one.name)
    Platform.expects(:family).returns("mswin32")
    BuilderStarter.expects(:system).with("cruise.cmd build #{@one.name} --trace")
    BuilderStarter.begin_builder(@one.name, true)

    Platform.expects(:family).returns("linux")
    BuilderStarter.expects(:fork).returns(nil)
    BuilderStarter.expects(:exec).with("#{RAILS_ROOT}/cruise build #{@one.name} --trace")
    BuilderStarter.begin_builder(@one.name, true)  
  end

  def test_on_win32_begin_builder_should_thread_to_run_builder_command
    Thread.expects(:new).with(@one.name).yields(@one.name)
  
    Platform.expects(:family).returns("mswin32")
    BuilderStarter.expects(:system).with("cruise.cmd build #{@one.name} ")
    
    BuilderStarter.begin_builder(@one.name, false)
  end
  
  def test_on_non_win32_begin_builder_should_fork_and_execute_builder_command
    Platform.expects(:family).returns("linux")
    BuilderStarter.expects(:fork).returns(nil)
    BuilderStarter.expects(:exec).with("#{RAILS_ROOT}/cruise build #{@one.name} ")
    
    BuilderStarter.begin_builder(@one.name, false)
  end
end
