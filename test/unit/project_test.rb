require 'date'
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectTest < Test::Unit::TestCase
  include FileSandbox
  
  def setup
    @svn = Subversion.new(:url => 'file://foo', :username => 'bob', :password => 'cha')
    @project = Project.new("lemmings", @svn)
  end

  def test_properties
    assert_equal("lemmings", @project.name)
    assert_equal("bob", @project.source_control.username)
  end

  def test_memento
    expected_result = <<-EOL
Project.configure do |project|
  project.source_control = Subversion.new(:url => 'file://foo', :username => 'bob', :password => 'cha')
  project.email_notifier.emails = [
    "jss@thoughtworks.com",
    "andrew@gmail.com",
    "bob@andrews.com"
  ]
end
    EOL

    @project.email_notifier.emails << "jss@thoughtworks.com" << "andrew@gmail.com" << "bob@andrews.com"
    assert_equal expected_result, @project.memento
  end

  def test_builds
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      sandbox.new :file => "build-1/build_status = success"
      sandbox.new :file => "build-10/build_status = success"
      sandbox.new :file => "build-3/build_status = failure"
      sandbox.new :file => "build-5/build_status = success"

      assert_equal("1 - success, 3 - failure, 5 - success, 10 - success",
                   @project.builds.collect {|b| "#{b.label} - #{b.status}"}.join(", "))

      assert_equal(10, @project.last_build.label)
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
      build = new_mock_build(5)
      build.stubs(:artifacts_directory).returns(sandbox.root)

      @project.expects(:builds).returns([])
      @svn.expects(:latest_revision).returns(revision)
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary

      @svn.verify
      build.verify
    end
  end

  def test_build_if_necessary_should_generate_events
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      revision = new_revision(5)
      build = new_mock_build(5)
      build.stubs(:artifacts_directory).returns(sandbox.root)

      @project.expects(:builds).returns([])
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

      listener.verify
    end
  end

  def test_should_build_when_logs_are_not_current
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      @project.expects(:builds).returns([Build.new(@project, 1)])
      revision = new_revision(2)
      build = new_mock_build(2)
      build.stubs(:artifacts_directory).returns(sandbox.root)

      @svn.expects(:revisions_since).with(@project, 1).returns([revision])
      @svn.expects(:update).with(@project, revision)

      build.expects(:run)

      @project.build_if_necessary

      @svn.verify
      build.verify
    end
  end

  def test_should_not_build_when_logs_are_current
    in_sandbox do |sandbox|
      @project.path = sandbox.root

      @project.expects(:builds).returns([Build.new(@project, 2)])
      revision = new_revision(2)

      @svn.expects(:revisions_since).with(@project, 2).returns([])

      @project.build_if_necessary

      @svn.verify
    end
  end

  def new_revision(number)
    Revision.new(number, 'alex', DateTime.new(2005, 1, 1), 'message', [])
  end

  def new_mock_build(number)
    build = Object.new
    Build.expects(:new).with(@project, number).returns(build)
    build
  end
end
