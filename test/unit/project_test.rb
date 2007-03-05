require 'date'
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'email_notifier'

class ProjectTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @svn = Object.new
    @project = Project.new("lemmings")
    @project.source_control = @svn
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
  
  def test_should_build_with_no_logs
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      revision = new_revision(5)
      build = new_mock_build('5')

      build.stubs(:artifacts_directory).returns(sandbox.root)
      
      @project.stubs(:builds).returns([])
      @project.stubs(:config_modified?).returns(false)
      @svn.expects(:latest_revision).returns(revision)
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary
    end
  end

  def test_build_if_necessary_should_generate_events
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      revision = new_revision(5)
      build = new_mock_build('5')
      build.stubs(:artifacts_directory).returns(sandbox.root)

      @project.stubs(:builds).returns([])
      @project.stubs(:config_modified?).returns(false)
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

  def test_build_should_generate_event_when_build_is_broken
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      successful_build = stub_build(1)
      successful_build.stubs(:successful?).returns(true)
      successful_build.stubs(:failed?).returns(false)

      new_build = new_mock_build('2')
      new_build.stubs(:successful?).returns(false)
      new_build.stubs(:failed?).returns(true)
      new_build.expects(:run)
      
      @project.expects(:last_build).returns(successful_build)
      @project.stubs(:builds).returns([successful_build])
      @project.stubs(:log_changeset)
      @svn.stubs(:update)

      # event expectations
      listener = Object.new

      listener.expects(:build_started)
      listener.expects(:build_finished)
      listener.expects(:build_broken)
      @project.add_plugin listener

      @project.build([new_revision(2)])
    end

  end

  def test_build_should_detect_config_modifications
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      revision = new_revision(1)

      @svn.expects(:update).with(@project, revision) do |*args|
        sandbox.new :file => 'work/cruise_config.rb'
        true
      end

      FileUtils.mkdir_p 'build-1' 
      mock_build = Object.new
      Build.expects(:new).returns(mock_build)
      mock_build.expects(:artifacts_directory).returns('build-1')
      mock_build.expects(:abort)

      listener = Object.new
      listener.expects(:configuration_modified)
      @project.add_plugin listener

      assert_throws(:reload_project) { @project.build([revision]) }
    end
  end

  def test_notify_should_create_plugin_error_log_if_plugin_fails_and_notify_has_a_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      
      mock_build = Object.new
      mock_build.stubs(:artifacts_directory).returns(sandbox.root)

      listener = Object.new
      listener.expects(:build_finished).with(mock_build).raises(StandardError.new("Listener failed"))

      @project.add_plugin listener

      assert_raises('Error in plugin Object: Listener failed') { @project.notify(:build_finished, mock_build) }

      assert_match /^Listener failed at/, File.read("#{mock_build.artifacts_directory}/plugin_errors.log")
    end
  end

  def test_notify_should_not_fail_if_plugin_fails_and_notify_has_no_build_or_no_arguments_at_all
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      listener = Object.new
      listener.expects(:sleeping).raises(StandardError.new("Listener failed"))
      listener.expects(:doing_something).with(:foo).raises(StandardError.new("Listener failed with :foo"))

      @project.add_plugin listener

      assert_raises('Error in plugin Object: Listener failed') { @project.notify(:sleeping) }
      assert_raises('Error in plugin Object: Listener failed with :foo') { @project.notify(:doing_something, :foo) }
    end
  end

  def test_build_should_generate_event_when_build_is_fixed
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      failing_build = stub_build(1)
      failing_build.stubs(:successful?).returns(false)
      failing_build.stubs(:failed?).returns(true)

      new_build = new_mock_build('2')
      new_build.stubs(:successful?).returns(true)
      new_build.stubs(:failed?).returns(false)
      new_build.expects(:run)
      @project.expects(:last_build).returns(failing_build)
      @project.stubs(:builds).returns([failing_build])
      @project.stubs(:log_changeset)
      @svn.stubs(:update)

      # event expectations
      listener = Object.new

      listener.expects(:build_started)
      listener.expects(:build_finished)
      listener.expects(:build_fixed)
      @project.add_plugin listener

      @project.build([new_revision(2)])
    end

  end

  def test_should_build_when_logs_are_not_current
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      @project.stubs(:builds).returns([Build.new(@project, 1)])
      @project.stubs(:config_modified?).returns(false)
      revision = new_revision(2)
      build = new_mock_build('2')
      @project.stubs(:last_build).returns(nil)
      build.stubs(:artifacts_directory).returns(sandbox.root)      
      @svn.expects(:revisions_since).with(@project, 1).returns([revision])
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary
    end
  end

  def test_should_not_build_when_logs_are_current
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      @project.stubs(:config_modified?).returns(false)
      @project.stubs(:builds).returns([Build.new(@project, 2)])
      @svn.stubs(:revisions_since).with(@project, 2).returns([])

      @project.expects(:build).never

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
    
    assert_raises("Error in plugin Object: Plugin talking") { @project.notify(:hey_you) }
  end

  def test_notify_should_handle_multiple_plugin_errors
    plugin1 = Object.new
    plugin2 = Object.new
    
    @project.plugins << plugin1 << plugin2
    
    plugin1.expects(:hey_you).raises("Plugin 1 talking")
    plugin2.expects(:hey_you).raises("Plugin 2 talking")

    assert_raises("Errors in plugins:\n  Object: Plugin 1 talking\n  Object: Plugin 2 talking") { @project.notify(:hey_you) }
  end

  def test_request_build_should_start_builder_if_builder_was_down
    in_sandbox do |sandbox|
      @project.path = sandbox.root                        
      @project.expects(:builder_state_and_activity).times(2).returns('builder_down', 'sleeping')
      BuilderStarter.expects(:begin_builder).with(@project.name)
      @project.request_build
    end       
  end

  def test_request_build_should_generate_build_requested_file_and_notify_listeners
    @project.stubs(:builder_state_and_activity).returns('sleeping')
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      listener = Object.new
      listener.expects(:build_requested)
      @project.add_plugin listener

      @project.request_build
      assert File.file?(@project.build_requested_flag_file)
    end
  end
  
  def test_request_build_should_not_notify_listeners_when_a_build_requested_flag_is_already_set
    @project.stubs(:builder_state_and_activity).returns('building')
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :file => 'build_requested'

      listener = Object.new
      listener.expects(:build_requested).never
      
      @project.expects(:build_requested?).returns(true)
      @project.expects(:create_build_requested_flag_file).never

      @project.request_build
    end
  end
  
  def test_build_if_requested_should_build_if_build_requested_file_exists
    in_sandbox do |sandbox|      
      @project.path = sandbox.root
      sandbox.new :file => 'build_requested'
      @project.expects(:remove_build_requested_flag_file)
      @project.expects(:build)
      @project.build_if_requested
    end
  end
    
  def test_build_requested
    @project.stubs(:path).returns("a_path")
    File.expects(:file?).with(@project.build_requested_flag_file).returns(true)
    assert @project.build_requested?
  end
  
  def test_build_should_generate_new_label_if_same_name_label_exists    
    existing_build1 = stub_build('20')
    existing_build2 = stub_build('20.1')
    new_build = stub_build('20.2')
    new_build_with_interesting_number = stub_build('2')
                 
    project = Project.new('project1', @svn)
    @svn.stubs(:update)
    project.stubs(:log_changeset) 
    project.stubs(:builds).returns([existing_build1, existing_build2])
    project.stubs(:last_build).returns(nil)      
    Build.expects(:new).with(project, '20.2').returns(new_build) 
    project.build([new_revision(20)])

    Build.expects(:new).with(project, '2').returns(new_build)
    project.build([new_revision(2)])
  end
  
  def test_should_load_configuration_from_work_directory_and_then_root_directory
    in_sandbox do |sandbox|
      @project.path = sandbox.root 
      begin
        sandbox.new :file => 'work/cruise_config.rb', :with_contents => '$foobar=42; $barfoo = 12345'
        sandbox.new :file => 'cruise_config.rb', :with_contents => '$barfoo = 54321'
        @project.load_config
        assert_equal 42, $foobar
        assert_equal 54321, $barfoo
      ensure
        $foobar = $barfoo = nil
      end
    end
  end
  
  def test_should_remember_settings
    in_sandbox do |sandbox|
      @project.path = sandbox.root 
      sandbox.new :file => 'work/cruise_config.rb', :with_contents => 'good = 4'
      sandbox.new :file => 'cruise_config.rb', :with_contents => 'time = 5'
        
      @project.load_config
      
      assert_equal "good = 4\ntime = 5\n", @project.settings
    end
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

  def new_mock_build(label)
    build = Object.new
    Build.expects(:new).with(@project, label).returns(build)
    build.stubs(:artifacts_directory).returns("project1/build-#{label}")
    build.stubs(:last).returns(nil)
    build.stubs(:label).returns(label)
    build
  end
  
end

