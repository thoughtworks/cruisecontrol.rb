require File.dirname(__FILE__) + '/../test_helper'

class SubversionIntegrationTest < Test::Unit::TestCase
  include FileSandbox
  
  def setup
    setup_sandbox
  end
  
  def teardown
    teardown_sandbox
  end
  
  def test_checkout
    checkout 'passing_project'
    assert File.exists?("passing_project/passing_test.rb")
  end

  def test_subversion_log_should_work_if_it_has_either_existing_path_or_url
    checkout 'passing_project'

    Subversion.new(:path => 'passing_project').latest_revision
    Subversion.new(:path => 'foo', :url => fixture_repository_url).latest_revision
    assert_raises { Subversion.new(:path => 'foo').latest_revision }
  end
  
  def test_up_to_date
    checkout 'passing_project', :revision => 2

    expected_reasons = 
"New revision 7 detected
Revision 7 committed by averkhov on 2007-01-13 01:05:26
Making both revision labels up to date
  M /passing_project/revision_label.txt
  M /failing_project/revision_label.txt

Revision 4 committed by averkhov on 2007-01-11 21:02:03
and one more revision, for good measure
  M /passing_project/revision_label.txt
"
    assert_false @svn.up_to_date?(reasons = [], 3)
    assert_equal expected_reasons, reasons.join("\n")
  end

  def test_up_to_date_should_return_an_empty_array_for_uptodate_local_copy
    checkout 'passing_project'
    
    assert @svn.up_to_date?(reasons = [], 7)
    assert_equal "", reasons.join("\n")
  end
  
  def test_latest_externals_project_is_up_to_date
    checkout 'project_with_externals'
    
    assert @svn.up_to_date?
  end
  
  def test_up_to_date_is_false_on_project_with_missing_externals_in_local_copy
    checkout 'project_with_externals'
    FileUtils.rm_rf 'project_with_externals/external_path'
    
    assert_false @svn.up_to_date?
    
    @svn.update
    
    assert @svn.up_to_date?
  end
  
  def test_svn_update_makes_up_to_date_true_for_project_with_externals
    checkout 'project_with_externals', :revision => 27
    
    assert_false @svn.up_to_date?
    
    @svn.update
    
    assert @svn.up_to_date?    
  end
  
  def fixture_repository_url
    repository_path = File.expand_path("#{RAILS_ROOT}/test/fixtures/svn-repo")
    urlified_path = repository_path.sub(/^[a-zA-Z]:/, '').gsub('\\', '/')
    "file://#{urlified_path}"
  end

  def checkout(path, options = {})
    @svn = svn_for(path)
    @svn.checkout options[:revision], io = StringIO.new
  end
  
  def svn_for(path)
    Subversion.new :url => File.join(fixture_repository_url, path), :path => path
  end
end
