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
        full_path_file_name = File.join(Dir.pwd, "some_other_filename")
        setup_using_filename(full_path_file_name)
        status = InProgressBuildStatus.new(nil)
        deletion_marker = full_path_file_name + InProgressBuildStatus.deletion_marker_file_suffix
        status.build_finished(@mock_build)
        assert File.exists?(deletion_marker)
      end
    rescue Exception => e
      raise e,  "Maybe build_finished() did not close or unlock the file?\n\n" + e.message
    end
  end
  
  def test_delete_in_progress_build_status_file_if_any_deletes_marker_and_file
    exercise_delete_in_progress_build_status_file_if_any_in_sandbox("file.name", true, true, false, false)
  end 

  def test_delete_in_progress_build_status_file_if_any_deletes_marker_if_no_file
    exercise_delete_in_progress_build_status_file_if_any_in_sandbox("file.name", false, true, false, false)
  end    
   
  def test_delete_in_progress_build_status_file_if_any_does_not_delete_if_no_delete_marker
    exercise_delete_in_progress_build_status_file_if_any_in_sandbox("file.name", true, false, true, false)
  end   

  private
  def setup_using_filename(name)
    @mock_build = Object.new
    @mock_project = Object.new
    @mock_project.expects(:in_progress_build_status_file).at_least(1).returns(name)
    @mock_build.expects(:project).at_least(1).returns(@mock_project)
  end
  
  
  def exercise_delete_in_progress_build_status_file_if_any_in_sandbox(basefile_name, 
                                                                      create_basefile, create_delete_marker, 
                                                                      basefile_should_exist_after, delete_marker_should_exist_after)
    in_total_sandbox do
      project = Object.new
      full_path_file_name= File.join(Dir.pwd, basefile_name)
      project.expects(:in_progress_build_status_file).returns(full_path_file_name)
      if create_basefile
        f = File.open(full_path_file_name,'w') 
        f.close
      end
      deletion_marker = full_path_file_name + InProgressBuildStatus.deletion_marker_file_suffix
      if create_delete_marker
        f = File.open(deletion_marker,'w') 
        f.close
      end
      InProgressBuildStatus.delete_in_progress_build_status_file_if_any(project)
      
      assert_equal basefile_should_exist_after, File.exists?(full_path_file_name)  
      assert_equal delete_marker_should_exist_after, File.exists?(deletion_marker)  
    end
  end 
end