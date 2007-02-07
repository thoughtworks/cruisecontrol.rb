require 'date'
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'email_notifier'

class ProjectTest < Test::Unit::TestCase
  include FileSandbox
  
  def setup
    @svn = Subversion.new(:url => 'file://foo', :username => 'bob', :password => 'cha')
    @project = Project.new("lemmings")
  end

  def test_properties
    @project = Project.new("lemmings", Subversion.new(:username => 'bob'))
    assert_equal("lemmings", @project.name)
    assert_equal("bob", @project.source_control.username)
  end
  
  def test_default_scheduler
    assert_equal PollingScheduler, @project.scheduler.class
  end

  def test_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      sandbox.new :file => "build-1/build_status.success"
      sandbox.new :file => "build-10/build_status.success"
      sandbox.new :file => "build-3/build_status.failure"
      sandbox.new :file => "build-5/build_status.success"
      sandbox.new :file => "build-5.2/build_status.success"
      sandbox.new :file => "build-5.12/build_status.success"

      assert_equal("1 - success, 3 - failure, 5 - success, 5.2 - success, 5.12 - success, 10 - success",
                   @project.builds.collect {|b| "#{b.label} - #{b.status}"}.join(", "))

      assert_equal('10', @project.last_build.label)
    end
  end

  def test_builds_should_return_empty_array_when_project_has_no_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      assert_equal [], @project.builds
    end
  end

  def test_should_build_when_project_configurations_modified
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      @project.expects(:config_modifications?).returns(true)      
      @project.expects(:load_config_file)

      @project.expects(:new_revisions).returns(Array.new)
      @project.expects(:build)
      @project.build_if_necessary
    end
  end
  
  def test_should_build_with_no_logs
    in_sandbox do |sandbox|
      @project.source_control = @svn
      @project.path = sandbox.root

      revision = new_revision(5)
      build = new_mock_build(5)

      build.stubs(:artifacts_directory).returns(sandbox.root)
      
      @project.stubs(:builds).returns([])
      @project.stubs(:config_modifications?).returns(false)
      @svn.expects(:latest_revision).returns(revision)
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary
    end
  end

  def test_build_if_necessary_should_generate_events
    in_sandbox do |sandbox|
      @project.source_control = @svn
      @project.path = sandbox.root

      revision = new_revision(5)
      build = new_mock_build(5)
      build.stubs(:artifacts_directory).returns(sandbox.root)

      @project.stubs(:builds).returns([])
      @project.stubs(:config_modifications?).returns(false)
      @svn.expects(:latest_revision).returns(revision)
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      # event expectations
      listener = Object.new

      listener.expects(:polling_source_control)
      listener.expects(:new_revisions_detected).with([revision])
      listener.expects(:build_started).with(build)
      listener.expects(:build_finished).with(build)
      listener.expects(:sleeping)

      @project.add_plugin listener

      @project.build_if_necessary
    end
  end

  def test_build_should_generate_event_when_build_loop_crashes
    in_sandbox do |sandbox|
      @project.source_control = @svn
      @project.path = sandbox.root

      @project.expects(:builds).returns([])
      error = StandardError.new   
      @svn.expects(:latest_revision).raises(error)

      # event expectations
      listener = Object.new

      listener.expects(:polling_source_control)
      listener.expects(:build_loop_failed).with(error)
      listener.expects(:sleeping)
      @project.add_plugin listener
      assert_raises(error) { @project.build_if_necessary }
    end
  end

  def test_should_build_when_logs_are_not_current
    in_sandbox do |sandbox|
      @project.source_control = @svn
      @project.path = sandbox.root

      @project.stubs(:builds).returns([Build.new(@project, 1)])
      @project.stubs(:config_modifications?).returns(false)
      revision = new_revision(2)
      build = new_mock_build(2)
      build.stubs(:artifacts_directory).returns(sandbox.root)      
      @svn.expects(:revisions_since).with(@project, 1).returns([revision])
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary
    end
  end

  def test_should_not_build_when_logs_are_current
    in_sandbox do |sandbox|
      @project.source_control = @svn
      @project.path = sandbox.root
      @project.stubs(:config_modifications?).returns(false)
      @project.expects(:builds).returns([Build.new(@project, 2)])
      revision = new_revision(2)

      @svn.expects(:revisions_since).with(@project, 2).returns([])

      @project.build_if_necessary
    end
  end
  
  def test_either_rake_task_or_build_command_can_be_set_but_not_both
    @project.rake_task = 'foo'
    assert_raises("Cannot set build_command when rake_task is already defined") do
      @project.build_command = 'foo'
    end

    @project.rake_task = nil
    @project.build_command = 'foo'
    assert_raises("Cannot set rake_task when build_command is already defined") do
      @project.rake_task = 'foo'
    end
  end

  def test_notify_should_handle_plugin_error
    plugin = Object.new
    
    @project.plugins << plugin
    
    plugin.expects(:hey_you).raises("Plugin talking")
    
    assert_raises("Plugin error: Object: Plugin talking") { @project.notify(:hey_you) }
  end
  
  def test_notify_should_handle_multiple_plugin_errors
    plugin1 = Object.new
    plugin2 = Object.new
    
    @project.plugins << plugin1 << plugin2
    
    plugin1.expects(:hey_you).raises("Plugin 1 talking")
    plugin2.expects(:hey_you).raises("Plugin 2 talking")

    assert_raises("Plugin error:\n  Object: Plugin 1 talking\n  Object: Plugin 2 talking") { @project.notify(:hey_you) }
  end

  def test_determine_builder_state
    ProjectBlocker.expects(:blocked?).with(@project).returns(false)
    assert_equal Status::NOT_RUNNING, @project.builder_state
    
    ProjectBlocker.expects(:blocked?).with(@project).returns(true)
    assert_equal Status::RUNNING, @project.builder_state
  end

  def test_builder_and_build_states_tag
    build = Object.new    
    build.expects(:label).at_least(1).returns('2')
    build.expects(:status).at_least(1).returns('pingpong')
    
    @project.expects(:builder_state_and_activity).at_least(1).returns('running (sleeping)')
    @project.expects(:builds).at_least(1).returns([build])
    assert_equal "running(sleeping)2pingpong", @project.builder_and_build_states_tag
  end
  
  def test_return_builder_activity
    @builder_status = Object.new
    @project.builder_status = @builder_status
    
    ProjectBlocker.expects(:blocked?).with(@project).returns(true) 
    @builder_status.expects(:status).returns(:working)
    assert_equal :working, @project.builder_activity
  end
    
  def test_return_not_running_as_builder_activity_when_builder_is_not_running
    ProjectBlocker.expects(:blocked?).with(@project).returns(false)  
    assert_equal Status::NOT_RUNNING, @project.builder_activity
  end
  
  def test_should_not_return_builder_activity_when_status_is_not_running
    @project.expects(:builder_state).at_least(1).returns(Status::NOT_RUNNING)
    @project.expects(:builder_activity).times(0)

    assert_equal "not started", @project.builder_state_and_activity
  end

  def test_should_return_builder_activity_when_status_is_running
    @project.expects(:builder_state).at_least(1).returns(Status::RUNNING)
    @project.expects(:builder_activity).at_least(1).returns('mock status')

    assert_equal "running (mock status)", @project.builder_state_and_activity
  end
  
  def test_config_modifications_should_return_true_if_config_file_modified_since_last_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root                  
      new_mock_last_build_time(Time.now - 1)
      configTime = Time.now      
      configPath = File.join(@project.path, 'project_config.rb')
      File.expects(:mtime).with(configPath).returns(configTime)
      assert @project.config_modifications?         
    end       
  end
  
  def test_config_modifications_should_return_false_if_config_file_not_modified_since_last_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root      
      new_mock_last_build_time(Time.now)  
      configTime = Time.now - 1       
      configPath = File.join(@project.path, 'project_config.rb')
      File.expects(:mtime).with(configPath).returns(configTime)
      assert_false @project.config_modifications?         
    end       
  end
  
  def test_config_modifications_should_return_false_if_there_is_no_previous_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root                        
      @project.expects(:last_build).returns(nil) 
      assert_false @project.config_modifications?         
    end       
  end
  
  def test_request_force_build_should_generate_force_tag_file
    ForceBuildBlocker.expects(:block).with(@project)
    ForceBuildBlocker.expects(:release).with(@project)
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      assert_equal "The force build is pending now!"   , @project.request_force_build()  
      assert File.file?("#{@project.path}/#{Project::ForceBuildTagFileName}")     
    end
  end
  
  def test_request_force_build_should_take_no_effect_when_acquire_build_blocker_failed
    ForceBuildBlocker.expects(:block).with(@project).raises("failed to lock exception")
    ForceBuildBlocker.expects(:release).with(@project)  
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      assert_equal "Another build is pending already!" , @project.request_force_build()  
      assert !File.file?("#{@project.path}/#{Project::ForceBuildTagFileName}")
    end
  end
  
   def test_request_force_build_should_take_no_effect_if_force_build_tag_file_exists
    ForceBuildBlocker.expects(:block).with(@project)
    ForceBuildBlocker.expects(:release).with(@project)
    in_sandbox do |sandbox|      
      @project.path = sandbox.root
      sandbox.new :file => Project::ForceBuildTagFileName
      @project.expects(:touch_force_tag_file).never
      assert_equal "Another build is pending already!" , @project.request_force_build()  
   end
  end
  
  def test_should_force_build_if_force_build_tag_file_exists
    ForceBuildBlocker.expects(:block).with(@project)
    ForceBuildBlocker.expects(:release).with(@project)
    in_sandbox do |sandbox|      
      @project.path = sandbox.root
      sandbox.new :file => Project::ForceBuildTagFileName
      @project.expects(:remove_force_tag_file)
      @project.expects(:build)
      @project.force_build_if_requested
    end
  end
    
  def test_force_build_request_should_be_allowed_if_builder_sleeping_and_no_other_force_builder_exists
    @project.expects(:builder_activity).returns("sleeping")
    @project.expects(:force_build_requested?).returns(false)    
    assert @project.force_build_request_allowed?
  end
  
  def test_should_check_force_build_requested_by_checking_if_tag_file_existing
    @project.expects(:path).returns("a_path")
    File.expects(:file?).with(File.join("a_path",Project::ForceBuildTagFileName)).returns(true)
    assert @project.force_build_requested?
  end
  
  def test_build_should_generate_new_label_if_same_name_label_exists    
    existing_build1 = stub_build('20')
    existing_build2 = stub_build('20.001')
    new_build = stub_build('20.002')
    new_build_with_interesting_number = stub_build('2')
             
 
    project = Project.new('project1', @svn)
    @svn.stubs(:update)
    project.stubs(:log_changeset) 
    project.stubs(:builds).returns([existing_build1, existing_build2])
          
    Build.expects(:new).with(project, '20.002').returns(new_build) 
    project.build([new_revision(20)])

    Build.expects(:new).with(project, '2').returns(new_build)
    project.build([new_revision(2)])
  end
      
  private
  
  def stub_build(label)
    build = Object.new
    build.stubs(:label).returns(label)
    build.stubs(:artifacts_directory).returns("project1/build_#{label}")
    build.stubs(:run)
    build
  end
  
  def new_revision(number)
    Revision.new(number, 'alex', DateTime.new(2005, 1, 1), 'message', [])
  end

  def new_mock_build(number)
    build = Object.new
    Build.expects(:new).with(@project, number.to_s).returns(build)
    build
  end
  
  def new_mock_last_build_time(time)
      last_build = Object.new
      @project.expects(:last_build).returns(last_build)      
      last_build.expects(:time).returns(time)    
  end  
end

