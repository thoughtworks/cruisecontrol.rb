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
  
  def test_on_win32_begin_builder_should_thread_to_run_builder_command
    Thread.expects(:new).with(@one.name).yields(@one.name)
  
    Platform.expects(:family).returns("mswin32")
    BuilderStarter.expects(:system).with("cruise.cmd build #{@one.name}")
    
    BuilderStarter.begin_builder(@one.name)
  end
  
  def test_on_non_win32_begin_builder_should_fork_and_execute_builder_command
    Platform.expects(:family).returns("linux")
    BuilderStarter.expects(:fork).returns(nil)
    BuilderStarter.expects(:exec).with("#{RAILS_ROOT}/cruise build #{@one.name}")
    
    BuilderStarter.begin_builder(@one.name)
  end
end
