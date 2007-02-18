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
  
private
  def create_revision(number, committed_by, comment)
    Revision.new(number, committed_by, DateTime.new(2007, 01, 12, 18, 05, 26, Rational(-7, 24)),
                 comment, [ChangesetEntry.new('M', '/app/foo.txt')])  
  end
  
  def h(text)
    text
  end
  
end
