require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
class BuildBlockerTest < Test::Unit::TestCase
  
  def test_pid_file_name
    assert_equal 'build_in_progress.pid', BuildBlocker.pid_file_name
  end
  
  def test_cannot_lock_error_message
    expected_error =  "Another build has started on project 'foo'.\n" + 
            "Look for a process with a lock on file #{project.path}/build_in_progress.pid"
    assert_equal expected_error, BuildBlocker.cannot_lock_error_message(project)
  end
  
  def test_already_lock_error_message
    assert_equal "Another build is running on project 'foo'", BuildBlocker.already_lock_error_message(project)
  end
  
  private
  def project
    proj = Object.new
    proj.stubs(:name).returns("foo")
    proj.stubs(:path).returns(File.expand_path(File.dirname(__FILE__)) + '/foo')
    proj
  end
end