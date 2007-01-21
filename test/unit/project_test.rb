require 'date'
require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../sandbox')

class ProjectTest < Test::Unit::TestCase
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
    Sandbox.create do |sandbox|
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
    Sandbox.create do |sandbox|
      @project.path = sandbox.root
      assert_equal [], @project.builds
    end
  end

  def test_build_new_checkin_should_generate_events
    Sandbox.create do |sandbox|
      @project.path = sandbox.root
      
      
      revision = Revision.new(1, 'alex', DateTime.new(2005, 1, 1), 'message', [])
      mock_build = Object.new
      
      @svn.expects(:new_revisions).with(@project).returns([revision])
      Build.expects(:new).with(@project, revision.number).returns(mock_build)
      @svn.expects(:update).with(@project, revision)
      mock_build.expects(:artifacts_directory).returns(sandbox.root)
      mock_build.expects(:run)
      
      # event expectations
      listener = Object.new

      listener.expects(:polling_source_control)
      listener.expects(:new_revisions_detected).with([revision])
      listener.expects(:build_started).with(mock_build)
      listener.expects(:build_finished).with(mock_build)
      listener.expects(:sleeping)
      
      @project.add_plugin listener
      
      @project.build_new_checkin
      
      listener.verify
    end
  end
  
  

end
