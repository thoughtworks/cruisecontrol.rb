require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class InProgressBuildStatusTest < Test::Unit::TestCase
  include FileSandbox

  def test_build_started_creates_file
    setup_using_filename("some filename")
    status = InProgressBuildStatus.new(nil)
    @mock_build.stubs(:label).returns("a build label")
    File.expects(:open).with("some filename", 'w')
    status.build_started(@mock_build)
  end
  
  def test_build_finished_creates_deletion_marker_file
    begin
      in_total_sandbox do
        full_path_file_name=Dir.pwd + "./some other filename"
        setup_using_filename(full_path_file_name)
        status = InProgressBuildStatus.new(nil)
        deletion_marker = full_path_file_name + InProgressBuildStatus::DELETION_MARKER_FILE_SUFFIX
        status.build_finished(@mock_build)
        assert File.exists?(deletion_marker)
      end
    rescue Exception => e
      raise e,  "Maybe build_finished() did not close or unlock the file?\n\n" + e.message
    end
  end
  
  private
  def setup_using_filename(name)
    @mock_build = Object.new
    @mock_project = Object.new
    @mock_project.expects(:in_progress_build_status_file).at_least(1).returns(name)
    @mock_build.expects(:project).at_least(1).returns(@mock_project)
  end
end