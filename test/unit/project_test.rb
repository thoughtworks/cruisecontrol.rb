require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  include FileSandbox
  include BuildFactory
  include SourceControl

  setup do
    @svn = FakeSourceControl.new
    @project = Project.new(:name => "lemmings", :scm => @svn)
  end

  context "#scheduler" do
    test "should be a polling scheduler by default" do
      assert_equal PollingScheduler, @project.scheduler.class
    end
  end

  context "#last_build" do
    test "should correctly retrieve the last build based on the numbers of previous builds" do
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
  end

  context "#last_complete_build" do
    test "should filter out builds that aren't yet complete" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        sandbox.new :directory => "build-1-success.in1s/"
        sandbox.new :directory => "build-2-failure.in1s/"
        sandbox.new :directory => "build-3/"
        assert_equal '2', @project.last_complete_build.label
      end
    end

    test "should return nil when there are no complete builds" do
      in_sandbox do |sandbox|
        sandbox.new :directory => "build-3/"
        assert_nil @project.last_complete_build
      end
    end
  end

  context "#previously_built?" do
    test "should return true if there is a complete build" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        sandbox.new :directory => "build-1-success.in1s/"
        assert @project.previously_built?
      end
    end

    test "should return false if there are no previous builds" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        assert !@project.previously_built?
      end
    end
  end
  
  context "#builds" do
    test "should return empty array when project has no builds" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        assert_equal [], @project.builds
      end
    end
  end

  context "#build_if_necessary" do
    # TODO Drastically reduce the use of mocking in these tests if possible.

    test "should build with no logs" do
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

    test "should generate events" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root

        revision = new_revision(5)
        build = new_mock_build('5')
        build.stubs(:artifacts_directory).returns(sandbox.root)
        build.stubs(:successful?).returns(false)
        build.stubs(:failed?).returns(false)

        @project.stubs(:builds).returns([OpenStruct.new(:successful? => false, :failed? => false)])
        @project.stubs(:config_modified?).returns(false)
        @svn.stubs(:up_to_date?).with{ |reasons| reasons << revision }.returns(false)
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

    test "should generate an event when the build loop crashes" do
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

    test "should build when logs are not current" do
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

    test "should not build when logs are current" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        @project.stubs(:config_modified?).returns(false)
        @project.stubs(:builds).returns([Build.new(@project, 2)])
        @svn.stubs(:revisions_since).with(@project, 2).returns([])

        @project.expects(:build).never

        @project.build_if_necessary
      end
    end
  end

  context "#build" do
    test "should fail if there is a subversion error" do
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

    test "should generate an event when the build is broken" do
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

    test "should detect if the configuration file changes and reload the project if so" do
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

    test "should generate an event if the build is fixed" do
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

    test "should generate a new label if a label with that same name already exists" do
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

    test "should perform a clean checkout if the flag is set" do
      in_sandbox do |sandbox|
        @project.do_clean_checkout :always
        @project.path = sandbox.root
        @svn.expects(:clean_checkout).with(Subversion::Revision.new(5), anything)

        @project.build(new_revision(5))
      end
    end

    test "should not perform a build when there are no revisions" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        @svn.stubs(:latest_revision).returns(nil)

        assert_nil @project.build
      end
    end

    test "should perform a build even if no changes were made since the last build" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        @project.stubs(:builds).returns [stub_build(1), stub_build(2)]
        @svn.stubs(:revisions_since).returns([])
        @svn.stubs(:latest_revision).returns(new_revision(2))
        @svn.expects(:update)

        assert @project.build
      end
    end

    test "should utilize the BuildSerializer to serialize its output" do
      Configuration.stubs(:serialize_builds).returns(true)
      project = Project.new(:name => "test")
      BuildSerializer.expects(:serialize).yields
      project.expects(:build_without_serialization)

      project.build []
    end
  end

  context "#build_if_requested" do
    test "should build if build_requested file exists" do
      in_sandbox do |sandbox|      
        @project.path = sandbox.root
        revision = @project.source_control.add_revision :message => "A super special feature", :number => 1
        
        sandbox.new :file => 'build_requested'
        @project.stubs(:remove_build_requested_flag_file)
        @project.expects(:build).with(revision, ['Build was manually requested.', '1: A super special feature'])
        @project.build_if_requested
      end
    end
    
    test "should specify build requested reason" do
      in_sandbox do |sandbox|      
        @project.path = sandbox.root
        sandbox.new :file => 'build_requested'
        @project.expects(:remove_build_requested_flag_file)
        @project.expects(:build)
        @project.build_if_requested
      end    
    end

    test "should allow you to request a build" do
      @project.stubs(:path).returns("a_path")
      File.expects(:file?).with(@project.build_requested_flag_file).returns(true)
      assert @project.build_requested?
    end
  end

  context "#notify" do
    test "should log a plugin error if a plugin fails" do
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

    test "should not log a plugin error if a plugin fails and notify is not provided with a build argument" do
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

    test "should handle a plugin error" do
      BuilderPlugin.expects(:known_event?).with(:hey_you).returns true
      plugin = Object.new
      @project.plugins << plugin
      
      plugin.expects(:hey_you).raises("Plugin talking")
      
      assert_raise_with_message(RuntimeError, "Error in plugin Object: Plugin talking") do
        @project.notify(:hey_you)
      end
    end

    test "should handle multiple plugin errors" do
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

    test "should raise an exception when notified with an unknown event" do
      BuilderPlugin.expects(:known_event?).returns false
      assert_raise RuntimeError do
        @project.notify :some_random_event
      end
    end
  end

  context "#build_command" do
    test "should be able to set either rake task or build_command but not both" do
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
  end
  
  context "#request_build" do
    test "should start the builder if the builder was down" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root                        
        @project.expects(:builder_state_and_activity).times(2).returns('builder_down', 'sleeping')
        BuilderStarter.expects(:begin_builder).with(@project.name)
        @project.request_build
      end       
    end

    test "should generate a build_requested file and notify listeners" do
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
    
    test "should not notify listeners when a build requested flag is already set" do
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
  end

  context "#kill_build" do
    test "should be able to kill a build on demand" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        Platform.expects(:kill_project_builder).with(@project.name)
        @project.kill_build
      end
    end
  end
  
  context "#force_build" do
    test "should be able to force a build on demand" do
      in_sandbox do |sandbox|      
        @project.path = sandbox.root
        revision = @project.source_control.add_revision :message => "A super special feature", :number => 1
        @project.expects(:build).with(revision, ['Custom message.', '1: A super special feature'])
        @project.force_build('Custom message.')
      end    
    end
  end

  context "#load_config" do
    test "should attempt to load the configuration from work directory and then root directory" do
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
    
    test "should mark the config invalid if an exception is raised during load_config" do
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
    
    test "should remember previous configuration settings" do
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
  end
  
  context "#last_complete_build_status" do
    test "should be 'failed' if builder status is fatal" do
      builder_status = Object.new
      builder_status.expects(:"fatal?").returns(true)
      BuilderStatus.expects(:new).with(@project).returns(builder_status)
      assert_equal "failed", @project.last_complete_build_status
    end
  end   
  
  context "#find_build" do
    test "should be able to get a previous build" do
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
    
    test "should be able to get the next build" do
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
  end
  
  context "#last_builds" do
    test "should be able to retrieve the last n builds" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root
        sandbox.new :directory => "build-1-success.in1s/"
        sandbox.new :directory => "build-2-failure.in1s/"
        sandbox.new :directory => "build-3/"
        
        assert_equal 2, @project.last_builds(2).length
        assert_equal 3, @project.last_builds(5).length
      end
    end
  end

  context "#do_clean_checkout?" do
    test "should return true based on the current time relative to the set do_clean_checkout interval" do
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

    test "should always be true if do_clean_checkout is called without any args" do
      in_sandbox do |sandbox|
        @project.path = sandbox.root

        assert !@project.do_clean_checkout?, "by default should be off"
        
        @project.do_clean_checkout
        
        assert @project.do_clean_checkout?
        assert @project.do_clean_checkout?
      end
    end
  end

  context "#triggered_by" do
    test "should include a source control change trigger by default in a new project" do
      project = Project.new(:name => 'foo')
      trigger_classes = project.triggered_by.map(&:class)
      assert_equal [ChangeInSourceControlTrigger], trigger_classes
    end

    test "should accumulate values as it's successively called" do
      project = Project.new(:name => 'foo')

      project.triggered_by = []
      assert_equal [], project.triggered_by

      project.triggered_by 1
      assert_equal [1], project.triggered_by

      project.triggered_by 2, 3
      assert_equal [1, 2, 3], project.triggered_by
    end

    test "should convert strings and symbols to successful build triggers" do
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
  end

  context "#path" do
    test "should apply to the source control's path" do
      assert_equal(@project.path.join("work").to_s, @svn.path)
      @project.path = "foo"
      assert_equal(File.expand_path("foo/work"), @svn.path)
    end
  end  
  
  context "#add_plugin" do
    test "should be able to access a plugin by its name after adding it" do
      plugin = BuildReaper.new(@project)
      @project.add_plugin plugin
      assert_equal plugin, @project.build_reaper
    end
    
    test "should raise an exception if already configured" do
      assert_raise RuntimeError do
        @project.add_plugin BuildReaper.new(@project)
        @project.add_plugin BuildReaper.new(@project)
      end
    end
  end
  
  context ".all" do
    test "should return all existing projects" do
      svn = FakeSourceControl.new("bob")
      one = Project.new(:name => "one", :scm => @svn)
      two = Project.new(:name => "two", :scm => @svn)
      
      in_sandbox do |sandbox|
        sandbox.new :file => "one/cruise_config.rb", :with_content => ""
        sandbox.new :file => "two/cruise_config.rb", :with_content => ""
        assert_equal %w(one two), Project.all(sandbox.root).map(&:name)
      end
    end

    test "should always reload project objects" do
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
  end
  
  context ".load_project" do
    test "should load the project in the given directory" do
      in_sandbox do |sandbox|
        sandbox.new :file => 'one/cruise_config.rb', :with_content => ''

        new_project = Project.load_project(File.join(sandbox.root, 'one'))

        assert_equal('one', new_project.name)
        assert_equal(File.join(sandbox.root, 'one'), new_project.path)
      end
    end

    test "should load a project without any configuration" do
      in_sandbox do |sandbox|
        sandbox.new :directory => "myproject/work/.svn"
        sandbox.new :directory => "myproject/builds-1"

        new_project = Project.load_project(sandbox.root + '/myproject')

        assert_equal("myproject", new_project.name)
        assert_equal(SourceControl::Subversion, new_project.source_control.class)
        assert_equal(sandbox.root + "/myproject", new_project.path)
      end
    end
  end
  
  context ".create" do
    test "should add a new project" do
      in_sandbox do |sandbox|
        Project.create "one", @svn, sandbox.root
        Project.create "two", @svn, sandbox.root
        assert_equal %w(one two), Project.all(sandbox.root).map(&:name)
      end
    end

    test "should check out an existing project" do
      in_sandbox do |sandbox|
        Project.create "one", @svn, sandbox.root
        assert SandboxFile.new('one/work').exists?
        assert SandboxFile.new('one/work/README').exists?
      end
    end

    test "should clean up after itself if the source control throws an exception" do
      in_sandbox do |sandbox|
        @svn.expects(:checkout).raises("svn error")

        assert_raise RuntimeError, 'svn error' do
          Project.create "one", @svn, sandbox.root
        end
        
        assert_false SandboxFile.new('one/work').exists?
        assert_false SandboxFile.new('one').exists?
      end
    end

    test "should not allow you to add the same project twice" do
      in_sandbox do |sandbox|
        project = Project.create "one", @svn, sandbox.root
        assert_raise RuntimeError, "Project named \"one\" already exists in #{sandbox.root}" do
          Project.create "one", @svn, sandbox.root
        end
        assert File.directory?(project.path), "Project directory does not exist."
      end
    end
  end

  context "#uses_bundler?" do
    test "should be false if the use_bundler setting has been overridden to false" do
      @project.use_bundler = false
      assert_false @project.uses_bundler?
    end

    test "should be false if the project does not have a Gemfile" do
      File.stubs(:exist?).with(@project.gemfile).returns false
      assert_false @project.uses_bundler?
    end

    test "should be true if the project has a Gemfile and use_bundler= has not be overridden" do
      File.stubs(:exist?).with(@project.gemfile).returns true
      assert @project.uses_bundler?
    end

    test "should use overridden Gemfile value for determining if the file exists" do
      @project.gemfile = "HEY_GUYS_GEMFILE_IS_RIGHT_HERE"
      File.expects(:exist?).with(File.join(@project.local_checkout, "HEY_GUYS_GEMFILE_IS_RIGHT_HERE"))
      @project.uses_bundler?
    end
  end

  context "#gemfile" do
    test "should default to a reasonable Gemfile value" do
      assert_equal File.join(@project.local_checkout, "Gemfile"), @project.gemfile
    end

    test "should include the project's checked-out path if the Gemfile is reset" do
      @project.gemfile = "little_treasures/HEY_GUYS_GEMFILE_IS_RIGHT_HERE"
      assert_equal File.join(@project.local_checkout, "little_treasures/HEY_GUYS_GEMFILE_IS_RIGHT_HERE"), @project.gemfile
    end
  end

  context "#environment" do
    test "should return empty Hash when no environment variables specified" do
      assert_equal({}, @project.environment)
    end

    test "should allow assiging environment variables" do
      @project.environment["CC_DB_PREFIX"] = "master_"
      @project.environment["CC_HBASE_ENABLED"] = "false"
      assert_equal({ "CC_DB_PREFIX" => "master_", "CC_HBASE_ENABLED" => "false" }, @project.environment)
    end
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
