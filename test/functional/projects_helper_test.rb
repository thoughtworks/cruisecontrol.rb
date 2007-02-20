require File.dirname(__FILE__) + '/../test_helper'
require 'revision'

class ProjectsHelperTest < Test::Unit::TestCase
  include ProjectsHelper
  include ApplicationHelper
  include FileSandbox
  
  def test_show_revisions_in_build_for_single_revision
     revisions = [create_revision(42, 'arthur', 'Checking in code')]
     output = show_revisions_in_build revisions
     assert_match /arthur/, output
     assert_match /Checking in code/, output
  end

  def test_show_revision_revisions_in_build_for_multiple_revisions
    revisions = [create_revision(42, 'arthur', 'Checking in code'),
                 create_revision(43, 'joe', 'Checking in more code')]
    output = show_revisions_in_build revisions
    assert_match /arthur, joe/, output
    assert !output.include?('Comments')
    assert !output.include?('Checking in')
  end

  def test_show_revision_revisions_in_build_for_multiple_revisions_with_non_unique_author
    revisions = [create_revision(42, 'arthur', 'Checking in code'), 
                 create_revision(43, 'joe', 'Checking in more code'),
                 create_revision(44, 'arthur', 'Checking in more and more code')]     
    output = show_revisions_in_build revisions
    assert_match /arthur, joe/, output
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

  def test_map_to_cctray_project_status
    assert_equal 'Success', map_to_cctray_project_status('success')
    assert_equal 'Unknown', map_to_cctray_project_status('never_built')
    assert_equal 'Failure', map_to_cctray_project_status('failed')
    assert_equal 'Unknown', map_to_cctray_project_status('whatever')
  end

  def test_map_to_cctray_activity
    assert_equal 'CheckingModifications', map_to_cctray_activity('checking_for_modifications')
    assert_equal 'Building', map_to_cctray_activity('building')
    assert_equal 'Sleeping', map_to_cctray_activity('sleeping')
    assert_equal 'Sleeping', map_to_cctray_activity('builder_down')
    assert_equal 'Unknown', map_to_cctray_project_status('whatever')
  end
  
  private

  def create_revision(number, committed_by, comment)
    Revision.new(number, committed_by, DateTime.new(2007, 01, 12, 18, 05, 26, Rational(-7, 24)),
                 comment, [ChangesetEntry.new('M', '/app/foo.txt')])  
  end
  
  def h(text)
    text
  end
  
end
