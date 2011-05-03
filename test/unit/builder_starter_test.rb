require 'test_helper'

class BuilderStarterTest < ActiveSupport::TestCase
  include FileSandbox
  
  def setup
    @svn = FakeSourceControl.new("bob")
    @one = Project.new(:name => "one", :scm => @svn)
    @two = Project.new(:name => "two", :scm => @svn)
  end
  
  def test_start_builders_should_begin_builder_for_each_project
    Project.expects(:all).returns([@one, @two])
    
    BuilderStarter.expects(:begin_builder).with(@one.name)
    BuilderStarter.expects(:begin_builder).with(@two.name)
    
    BuilderStarter.start_builders
  end
  
  def test_should_use_platform_specific_executable
    Platform.stubs(:family).returns("mswin32")
    Platform.stubs(:interpreter).returns("ruby")
    Platform.expects(:create_child_process).with(@one.name, "ruby #{Rails.root}/cruise build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)

    Platform.stubs(:family).returns("linux")
    Platform.stubs(:interpreter).returns("ruby")
    Platform.expects(:create_child_process).with(@one.name, "#{Rails.root}/cruise build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)
  end

  def test_should_accomodate_jruby_interpreter
    Platform.stubs(:family).returns("mswin32")
    Platform.stubs(:interpreter).returns("jruby")
    Platform.expects(:create_child_process).with(@one.name, "jruby #{Rails.root}/cruise build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)

    Platform.stubs(:family).returns("linux")
    Platform.stubs(:interpreter).returns("jruby")
    Platform.expects(:create_child_process).with(@one.name, "jruby #{Rails.root}/cruise build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)
  end

  def test_should_invoke_cruise_in_verbose_mode
    $VERBOSE_MODE = true
    begin
      Platform.stubs(:family).returns("mswin32")
      Platform.stubs(:interpreter).returns("ruby")

      Platform.expects(:create_child_process).with(@one.name, "ruby #{Rails.root}/cruise build #{@one.name} --trace")

      BuilderStarter.begin_builder(@one.name)

      Platform.stubs(:family).returns("linux")
      Platform.stubs(:interpreter).returns("ruby")
      Platform.expects(:create_child_process).with(@one.name, "#{Rails.root}/cruise build #{@one.name} --trace")
      BuilderStarter.begin_builder(@one.name)
    ensure
      $VERBOSE_MODE = false
    end
  end

  def test_if_someone_in_their_infinite_wisdom_runs_ccrb_from_a_weird_path_it_should_be_escaped
    Platform.stubs(:family).returns("mswin32")

    Platform.stubs(:interpreter).returns("ruby")
    CommandLine.expects(:escape).with(Rails.root.join('cruise')).returns('escaped_path')
    Platform.expects(:create_child_process).with(@one.name, "ruby escaped_path build #{@one.name}")
    BuilderStarter.begin_builder(@one.name)

    Platform.stubs(:interpreter).returns("jruby")
    CommandLine.expects(:escape).with(Rails.root.join('cruise')).returns('escaped_path')
    Platform.expects(:create_child_process).with(@one.name, "jruby escaped_path build #{@one.name}")

    BuilderStarter.begin_builder(@one.name)
  end

end
