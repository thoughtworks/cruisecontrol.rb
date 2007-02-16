require File.dirname(__FILE__) + '/../test_helper'
require 'revision'

class ProjectsHelperTest < Test::Unit::TestCase
  include ProjectsHelper
  include ApplicationHelper
  include FileSandbox
  
  def test_show_revisions_in_build_for_single_revision
     revisions = [create_revision(42, 'arthur', 'Checking in code')]
     output = show_revisions_in_build revisions
     assert output.include?('arthur')
     assert output.include?('Checking in code')
  end
  
  def test_show_revision_revisions_in_build_for_multiple_revisions
    revisions = [create_revision(42, 'arthur', 'Checking in code'), 
                 create_revision(43, 'joe', 'Checking in more code'),
                 create_revision(44, 'arthur', 'Checking in more and more code')]     
    output = show_revisions_in_build revisions
    assert output.include?('arthur, joe')
    assert !output.include?('Comments')    
    assert !output.include?('Checking in')     
  end
  
  def test_show_revisions_in_build_for_no_revisions
    assert_equal '', show_revisions_in_build([])
  end

  def test_show_revisions_in_build_for_empty_comments
     revisions = [create_revision(42, 'arthur', '')]
     output = show_revisions_in_build revisions
     assert !output.include?('Comments:')
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
  def create_revision(number, committed_by, comment)
    Revision.new(number, committed_by, DateTime.new(2007, 01, 12, 18, 05, 26, Rational(-7, 24)),
                 comment, [ChangesetEntry.new('M', '/app/foo.txt')])  
  end
  
  def h(text)
    text
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
      deletion_marker = full_path_file_name + InProgressBuildStatus::DELETION_MARKER_FILE_SUFFIX
      if create_delete_marker
        f = File.open(deletion_marker,'w') 
        f.close
      end
      delete_in_progress_build_status_file_if_any(project)
      
      assert_equal basefile_should_exist_after, File.exists?(full_path_file_name)  
      assert_equal delete_marker_should_exist_after, File.exists?(deletion_marker)  
    end
  end 
  
end
