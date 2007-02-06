require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
class ForceBuildBlockerTest < Test::Unit::TestCase
  
  def test_pid_file_name
    assert_equal 'force_build_blocker.pid', ForceBuildBlocker.pid_file_name
  end
  
  def test_cannot_lock_error_message
    expected_error =  "Another force build has started on project 'foo'.\n" + 
            "Look for a process with a lock on file #{project.path}/force_build_blocker.pid"
    assert_equal expected_error, ForceBuildBlocker.cannot_lock_error_message(project)
  end
  
  def test_already_lock_error_message
    assert_equal "Another force build is running on project 'foo'", ForceBuildBlocker.already_lock_error_message(project)
  end
  
  private
  def project
    proj = Object.new
    proj.stubs(:name).returns("foo")
    proj.stubs(:path).returns(File.expand_path(File.dirname(__FILE__)) + '/foo')
    proj
  end
end