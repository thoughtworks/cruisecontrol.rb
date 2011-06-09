require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  include FileSandbox
  include BuildFactory
  include SourceControl

  def setup
    @svn = FakeSourceControl.new
    @project = Project.new(:name => "lemmings", :scm => @svn)
  end

  def test_default_scheduler
    assert_equal PollingScheduler, @project.scheduler.class
  end

  def test_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      sandbox.new :directory => "build-1-success.in1s/"
      sandbox.new :directory => "build-10-success.in1s/"
      sandbox.new :directory => "build-3-failure.in1s/"
      sandbox.new :directory => "build-5-success.in1s/"
      sandbox.new :directory => "build-5.2-success.in1s/"
      sandbox.new :directory => "build-5.12-success.in1s/"

      assert_equal("1 - success - 1, 3 - failure - 3, 5 - success - 5, 5.2 - success - 5, 5.12 - success - 5, 10 - success - 10",
                   @project.builds.collect {|b| "#{b.label} - #{b.status} - #{b.revision}"}.join(", "))

      assert_equal('10', @project.last_build.label)
    end
  end
  
  def test_project_should_know_last_complete_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :directory => "build-1-success.in1s/"
      sandbox.new :directory => "build-2-failure.in1s/"
      sandbox.new :directory => "build-3/"
      assert_equal '2', @project.last_complete_build.label
    end
  end

  def test_last_complete_build_should_return_nil_when_there_are_no_complete_builds
    in_sandbox do |sandbox|
      sandbox.new :directory => "build-3/"
      assert_nil @project.last_complete_build
    end
  end
  
  def test_previously_built_should_return_true_if_there_is_a_complete_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :directory => "build-1-success.in1s/"
      assert @project.previously_built?
    end
  end
  
  def test_previously_built_should_return_false_if_there_are_no_previous_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      assert !@project.previously_built?
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
      build.stubs(:successful?).returns(true)
      
      @project.stubs(:builds).returns([])
      @project.stubs(:config_modified?).returns(false)
      @svn.stubs(:latest_revision).returns(revision)
      @svn.expects(:update).with(revision)

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
      build.stubs(:successful?).returns(false)
      build.stubs(:failed?).returns(false)

      @project.stubs(:builds).returns([OpenStruct.new(:successful? => false, :failed? => false)])
      @project.stubs(:config_modified?).returns(false)
      @svn.stubs(:up_to_date?).with{|reasons| reasons << [revision]}.returns(false)
      @svn.stubs(:latest_revision).returns(revision)
      @svn.expects(:update).with(revision)

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
      listener.expects(:build_loop_failed).with(error)
      @project.add_plugin listener
      assert_raise(StandardError) { @project.build_if_necessary }
    end
  end
  
  def test_build_should_fail_if_subversion_error
    in_sandbox do
      @project.path = sandbox.root

      error = StandardError.new("something bad happened")
      @project.expects(:update_project_to_revision).raises(error)

      assert_raise_with_message(StandardError, "something bad happened") do
        @project.build(new_revision(5))
      end
      
      build = @project.builds.first
      assert build.failed?
      assert_equal "something bad happened", build.error
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
      @project.stubs(:new_revisions).returns(nil)
      @svn.stubs(:update)

      # event expectations
      listener = Object.new

      listener.expects(:build_started)
      listener.expects(:build_finished)
      listener.expects(:build_broken)
      @project.add_plugin listener

      @project.build(new_revision(2))
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

      FileUtils.mkdir_p 'build-1-success.in40s' 
      mock_build = Object.new
      Build.stubs(:new).returns(mock_build)
      mock_build.stubs(:label).returns("1")
      mock_build.expects(:artifacts_directory).returns('build-1-success.in40s')
      mock_build.expects(:abort)
      @project.stubs(:new_revisions).returns(nil)
      
      listener = Object.new
      listener.expects(:configuration_modified)
      @project.add_plugin listener

      assert_throws(:reload_project) { @project.build(revision) }
    end
  end

  def test_notify_should_create_plugin_error_log_if_plugin_fails_and_notify_has_a_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      
      mock_build = Object.new
      mock_build.stubs(:artifacts_directory).returns(sandbox.root)
      mock_build.stubs(:label).returns("1")
      mock_build.stubs(:successful?).returns(true)

      listener = Object.new
      listener.expects(:build_finished).with(mock_build).raises(StandardError.new("Listener failed"))

      @project.add_plugin listener

      assert_raise_with_message(RuntimeError, 'Error in plugin Object: Listener failed') do
        @project.notify(:build_finished, mock_build)
      end

      assert_match /^Listener failed at/, File.read("#{mock_build.artifacts_directory}/plugin_errors.log")
    end
  end

  def test_notify_should_not_fail_if_plugin_fails_and_notify_has_no_build_or_no_arguments_at_all
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      listener = Object.new
      listener.expects(:sleeping).raises(StandardError.new("Listener failed"))
      listener.expects(:doing_something).with(:foo).raises(StandardError.new("Listener failed with :foo"))
      BuilderPlugin.stubs(:known_event?).returns true

      @project.add_plugin listener

      assert_raise_with_message(RuntimeError, 'Error in plugin Object: Listener failed') do
        @project.notify(:sleeping)
      end
      assert_raise_with_message(RuntimeError, 'Error in plugin Object: Listener failed with :foo') do
        @project.notify(:doing_something, :foo)
      end
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
      @project.stubs(:new_revisions).returns(nil)
      @svn.stubs(:update)

      # event expectations
      listener = Object.new

      listener.expects(:build_started)
      listener.expects(:build_finished)
      listener.expects(:build_fixed)
      @project.add_plugin listener

      @project.build(new_revision(2))
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
      build.stubs(:successful?).returns(true)
      @svn.stubs(:up_to_date?).with([]).returns(false)
      @svn.expects(:update).with(revision)
      @svn.expects(:latest_revision).returns(revision)

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
    assert_raise_with_message(RuntimeError, "Cannot set build_command when rake_task is already defined") do
      @project.build_command = 'foo'
    end

    @project.rake_task = nil
    @project.build_command = 'foo'
    assert_raise_with_message(RuntimeError, "Cannot set rake_task when build_command is already defined") do
      @project.rake_task = 'foo'
    end
  end

  def test_notify_should_handle_plugin_error
    BuilderPlugin.expects(:known_event?).with(:hey_you).returns true
    plugin = Object.new
    @project.plugins << plugin
    
    plugin.expects(:hey_you).raises("Plugin talking")
    
    assert_raise_with_message(RuntimeError, "Error in plugin Object: Plugin talking") do
      @project.notify(:hey_you)
    end
  end

  def test_notify_should_handle_multiple_plugin_errors
    BuilderPlugin.stubs(:known_event?).with(:hey_you).returns true
    plugin1 = Object.new
    plugin2 = Object.new
    
    @project.plugins << plugin1 << plugin2
    
    plugin1.expects(:hey_you).raises("Plugin 1 talking")
    plugin2.expects(:hey_you).raises("Plugin 2 talking")

    assert_raise_with_message(RuntimeError, "Errors in plugins:\n  Object: Plugin 1 talking\n  Object: Plugin 2 talking") do
      @project.notify(:hey_you)
    end
  end

  def test_request_build_should_start_builder_if_builder_was_down
    in_sandbox do |sandbox|
      @project.path = sandbox.root                        
      @project.expects(:builder_state_and_activity).times(2).returns('builder_down', 'sleeping')
      BuilderStarter.expects(:begin_builder).with(@project.name)
      @project.request_build
    end       
  end

  def test_kill_build_should_kill_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      Platform.expects(:kill_child_process).with(@project.name)
      @project.kill_build
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
      revision = @project.source_control.add_revision :message => "A super special feature", :number => 1
      
      sandbox.new :file => 'build_requested'
      @project.stubs(:remove_build_requested_flag_file)
      @project.expects(:build).with(revision, ['Build was manually requested.', '1: A super special feature'])
      @project.build_if_requested
    end
  end
  
  def test_build_if_requested_should_specify_build_requested_reason
    in_sandbox do |sandbox|      
      @project.path = sandbox.root
      sandbox.new :file => 'build_requested'
      @project.expects(:remove_build_requested_flag_file)
      @project.expects(:build)
      @project.build_if_requested
    end    
  end
    
  def test_force_build
    in_sandbox do |sandbox|      
      @project.path = sandbox.root
      revision = @project.source_control.add_revision :message => "A super special feature", :number => 1
      @project.expects(:build).with(revision, ['Custom message.', '1: A super special feature'])
      @project.force_build('Custom message.')
    end    
  end
    
  def test_build_requested
    @project.stubs(:path).returns("a_path")
    File.expects(:file?).with(@project.build_requested_flag_file).returns(true)
    assert @project.build_requested?
  end
  
  def test_build_should_generate_new_label_if_same_name_label_exists
    in_sandbox do |sandbox|
      existing_build1 = stub_build('20')
      existing_build2 = stub_build('20.1')
      new_build = stub_build('20.2')
      new_build_with_interesting_number = stub_build('2')

      project = Project.new(:name => 'project1', :scm => @svn)
      @svn.stubs(:update)
      project.path = sandbox.root
      project.stubs(:log_changeset)
      project.stubs(:builds).returns([existing_build1, existing_build2])
      project.stubs(:last_build).returns(nil)
      project.stubs(:new_revisions).returns(nil)

      Build.expects(:new).with(project, '20.2', true).returns(new_build)
      project.build(new_revision(20))

      Build.expects(:new).with(project, '2', true).returns(new_build)
      project.build(new_revision(2))
    end
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
  
  def test_should_mark_config_invalid_if_exception_raised_during_load_config
    in_sandbox do |sandbox|
      invalid_ruby_code = 'class Invalid'
      @project.path = sandbox.root 
      sandbox.new :file => 'work/cruise_config.rb', :with_contents => invalid_ruby_code
      @project.load_config
      assert @project.settings.empty?
      assert_equal invalid_ruby_code, @project.config_file_content.strip
      assert !@project.config_valid?
      assert_match /Could not load project configuration:/, @project.error_message
    end
  end
  
  def test_should_remember_settings
    in_sandbox do |sandbox|
      @project.path = sandbox.root 
      sandbox.new :file => 'work/cruise_config.rb', :with_contents => 'good = 4'
      sandbox.new :file => 'cruise_config.rb', :with_contents => 'time = 5'

      @project.load_config
      assert_equal "good = 4\ntime = 5\n", @project.settings
      assert @project.config_valid?
      assert @project.error_message.empty?
    end
  end
  
  def test_last_complete_build_status_should_be_failed_if_builder_status_is_fatal
    builder_status = Object.new
    builder_status.expects(:"fatal?").returns(true)
    BuilderStatus.expects(:new).with(@project).returns(builder_status)
    assert_equal "failed", @project.last_complete_build_status
  end
   
   
  def test_should_be_able_to_get_previous_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :directory => "build-1-success/"
      sandbox.new :directory => "build-2-failure/"
      sandbox.new :directory => "build-3"
      
      build = @project.find_build('2')
      assert_equal('1', @project.previous_build(build).label)
      
      build = @project.find_build('1')
      assert_equal(nil, @project.previous_build(build))
    end
  end
  
  def test_should_be_able_to_get_next_build
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :directory => "build-1-success.in1s/"
      sandbox.new :directory => "build-2-failure.in1s/"
      sandbox.new :directory => "build-3/"
      
      build = @project.find_build('1')
      assert_equal('2', @project.next_build(build).label)
      
      build = @project.find_build('2')
      assert_equal('3', @project.next_build(build).label)
      
      build = @project.find_build('3')
      assert_equal(nil, @project.next_build(build))
    end
  end
  
  def test_should_be_able_to_get_last_n_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      sandbox.new :directory => "build-1-success.in1s/"
      sandbox.new :directory => "build-2-failure.in1s/"
      sandbox.new :directory => "build-3/"
      
      assert_equal 2, @project.last_builds(2).length
      assert_equal 3, @project.last_builds(5).length
    end
  end

  def test_should_do_clean_checkout_if_flag_is_set
    in_sandbox do |sandbox|
      @project.do_clean_checkout :always
      @project.path = sandbox.root
      @svn.expects(:clean_checkout).with(Subversion::Revision.new(5), anything)

      @project.build(new_revision(5))
    end
  end
  
  def test_build_when_no_revision_yet
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      @svn.stubs(:latest_revision).returns(nil)

      assert_nil @project.build
    end
  end
  
  def test_build_should_still_build_even_when_no_changes_were_made
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      @project.stubs(:builds).returns [stub_build(1), stub_build(2)]
      @svn.stubs(:revisions_since).returns([])
      @svn.stubs(:latest_revision).returns(new_revision(2))
      @svn.expects(:update)

      assert @project.build
    end
  end

  def test_do_clean_checkout_every_x_hours
    in_sandbox do |sandbox|
      @project.path = sandbox.root
      marker = sandbox.root + '/last_clean_checkout_timestamp'
      
      now = Time.now
      Time.stubs(:now).returns(now)

      @project.do_clean_checkout :every => 1.hour
    
      assert @project.do_clean_checkout?
      assert !@project.do_clean_checkout?
      assert !@project.do_clean_checkout?
      
      now += 59.minutes
      Time.stubs(:now).returns(now)
      assert !@project.do_clean_checkout?
      
      now += 2.minutes
      Time.stubs(:now).returns(now)
      assert @project.do_clean_checkout?
      assert !@project.do_clean_checkout?

      @project.do_clean_checkout :every => 2.days
      now += 1.day + 23.hours
      Time.stubs(:now).returns(now)
      assert !@project.do_clean_checkout?

      now += 2.hours
      Time.stubs(:now).returns(now)
      assert @project.do_clean_checkout?
    end
  end
  
  def increment_time_by(seconds)
    now = Time.now
    Time.stubs(:now).returns(now + seconds)
    File.stubs(:mtime).returns(now + seconds)
  end

  def test_do_clean_checkout_always
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      assert !@project.do_clean_checkout?, "by default should be off"
      
      @project.do_clean_checkout
      
      assert @project.do_clean_checkout?
      assert @project.do_clean_checkout?
    end
  end


  def test_new_project_should_have_source_control_triggers
    project = Project.new(:name => 'foo')
    trigger_classes = project.triggered_by.map(&:class)
    assert_equal [ChangeInSourceControlTrigger], trigger_classes
  end


  def test_project_triggered_by
    project = Project.new(:name => 'foo')

    project.triggered_by = []
    assert_equal [], project.triggered_by

    project.triggered_by 1
    assert_equal [1], project.triggered_by

    project.triggered_by 2, 3
    assert_equal [1, 2, 3], project.triggered_by
  end

  def test_project_triggered_by_should_convert_strings_and_symbols_to_successful_build_triggers
    in_sandbox do |sandbox|
      project = create_project 'foo'
      create_project 'bar'
      create_project 'baz'

      project.triggered_by = ['foo', 123]
      project.triggered_by :bar
      project.triggered_by << :baz
      assert_equal [SuccessfulBuildTrigger.new(project, 'foo'), 123, SuccessfulBuildTrigger.new(project, 'bar'),
                    SuccessfulBuildTrigger.new(project, 'baz')],
                    project.triggered_by
    end
  end

  def test_builds_are_serialized
    Configuration.stubs(:serialize_builds).returns(true)
    project = Project.new(:name => "test")
    BuildSerializer.expects(:serialize).yields
    project.expects(:build_without_serialization)

    project.build []
  end
  
  def test_keep_scm_and_path_in_sync
    assert_equal(@project.path.join("work").to_s, @svn.path)
    @project.path = "foo"
    assert_equal(File.expand_path("foo/work"), @svn.path)
  end
  
  def test_plugins_should_be_accessible_by_their_name
    plugin = BuildReaper.new(@project)
    @project.add_plugin plugin
    assert_equal plugin, @project.build_reaper
  end
  
  def test_adding_a_plugin_should_raise_exception_if_already_configured
    assert_raise RuntimeError do
      @project.add_plugin BuildReaper.new(@project)
      @project.add_plugin BuildReaper.new(@project)
    end
  end
  
  def test_notifying_project_of_an_unknown_event_raises_exception
    BuilderPlugin.expects(:known_event?).returns false
    assert_raise RuntimeError do
      @project.notify :some_random_event
    end
  end
  
  def test_project_all_should_return_all_existing_projects
    svn = FakeSourceControl.new("bob")
    one = Project.new(:name => "one", :scm => @svn)
    two = Project.new(:name => "two", :scm => @svn)
    
    in_sandbox do |sandbox|
      sandbox.new :file => "one/cruise_config.rb", :with_content => ""
      sandbox.new :file => "two/cruise_config.rb", :with_content => ""
      assert_equal %w(one two), Project.all(sandbox.root).map(&:name)
    end
  end

  def test_project_all_should_always_reload_project_objects
    svn = FakeSourceControl.new("bob")
    one = Project.new(:name => "one", :scm => @svn)
    two = Project.new(:name => "two", :scm => @svn)
    
    in_sandbox do |sandbox|
      sandbox.new :file => "one/cruise_config.rb", :with_content => ""
      sandbox.new :file => "two/cruise_config.rb", :with_content => ""
      old_projects = Project.all(sandbox.root)
      
      sandbox.new :file => "three/cruise_config.rb", :with_content => ""
      current_projects = Project.all(sandbox.root)
      
      assert_not_equal old_projects, current_projects
      assert_not_same old_projects.first, current_projects.first
    end
  end
  
  test "Project.load_project should load the project in the given directory" do
    in_sandbox do |sandbox|
      sandbox.new :file => 'one/cruise_config.rb', :with_content => ''

      new_project = Project.load_project(File.join(sandbox.root, 'one'))

      assert_equal('one', new_project.name)
      assert_equal(File.join(sandbox.root, 'one'), new_project.path)
    end
  end

  test "Project.load_project should load a project without any configuration" do
    in_sandbox do |sandbox|
      sandbox.new :directory => "myproject/work/.svn"
      sandbox.new :directory => "myproject/builds-1"

      new_project = Project.load_project(sandbox.root + '/myproject')

      assert_equal("myproject", new_project.name)
      assert_equal(SourceControl::Subversion, new_project.source_control.class)
      assert_equal(sandbox.root + "/myproject", new_project.path)
    end
  end
  
  test "Project.create should add a new project" do
    in_sandbox do |sandbox|
      Project.create "one", @svn, sandbox.root
      Project.create "two", @svn, sandbox.root
      assert_equal %w(one two), Project.all(sandbox.root).map(&:name)
    end
  end

  test "Project.create should check out an existing project" do
    in_sandbox do |sandbox|
      Project.create "one", @svn, sandbox.root
      assert SandboxFile.new('one/work').exists?
      assert SandboxFile.new('one/work/README').exists?
    end
  end

  test "Project.create should clean up after itself if the source control throws an exception" do
    in_sandbox do |sandbox|
      @svn.expects(:checkout).raises("svn error")

      assert_raise RuntimeError, 'svn error' do
        Project.create "one", @svn, sandbox.root
      end
      
      assert_false SandboxFile.new('one/work').exists?
      assert_false SandboxFile.new('one').exists?
    end
  end

  test "Project.create should not allow you to add the same project twice" do
    in_sandbox do |sandbox|
      project = Project.create "one", @svn, sandbox.root
      assert_raise RuntimeError, "Project named \"one\" already exists in #{sandbox.root}" do
        Project.create "one", @svn, sandbox.root
      end
      assert File.directory?(project.path), "Project directory does not exist."
    end
  end

  test "Project#uses_bundler? should be false if the use_bundler setting has been overridden to false" do
    @project.use_bundler = false
    assert_false @project.uses_bundler?
  end

  test "Project#uses_bundler? should be false if the project does not have a Gemfile" do
    File.stubs(:exist?).with(@project.gemfile).returns false
    assert_false @project.uses_bundler?
  end

  test "Project#uses_bundler? should be true if the project has a Gemfile and use_bundler= has not be overridden" do
    File.stubs(:exist?).with(@project.gemfile).returns true
    assert @project.uses_bundler?
  end

  test "Project#uses_bundler? should use overridden Gemfile value for determining if the file exists" do
    @project.gemfile = "HEY_GUYS_GEMFILE_IS_RIGHT_HERE"
    File.expects(:exist?).with(File.join(@project.local_checkout, "HEY_GUYS_GEMFILE_IS_RIGHT_HERE"))
    @project.uses_bundler?
  end
  
  test "Project#gemfile should default to a reasonable Gemfile value" do
    assert_equal File.join(@project.local_checkout, "Gemfile"), @project.gemfile
  end

  test "Project#gemfile should include the project's checked-out path if the Gemfile is reset" do
    @project.gemfile = "little_treasures/HEY_GUYS_GEMFILE_IS_RIGHT_HERE"
    assert_equal File.join(@project.local_checkout, "little_treasures/HEY_GUYS_GEMFILE_IS_RIGHT_HERE"), @project.gemfile
  end
  
  private
  
    def stub_build(label)
      stub(
        :label => label, 
        :artifacts_directory => "project1/build-#{label}", 
        :successful? => true, 
        :run => nil
      )
    end

    def new_revision(number)
      SourceControl::Subversion::Revision.new(number, 'alex', DateTime.new(2005, 1, 1), 'message', [])
    end

    def new_mock_build(label)
      build = Object.new
      Build.expects(:new).with(@project, label, true).returns(build)
      build.stubs(:artifacts_directory).returns("project1/build-#{label}")
      build.stubs(:last).returns(nil)
      build.stubs(:label).returns(label)
      build.stubs(:successful?).returns(true)
      build
    end
end
