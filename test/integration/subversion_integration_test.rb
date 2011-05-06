require 'test_helper'

class SubversionIntegrationTest < ActiveSupport::TestCase
  include FileSandbox

  setup :setup_sandbox
  teardown :teardown_sandbox
  
  def test_checkout
    checkout 'passing_project'
    assert File.exists?("passing_project/passing_test.rb")
  end

  def test_subversion_log_should_work_if_it_has_either_existing_path_or_repository_location
    checkout 'passing_project'

    SourceControl::Subversion.new(:path => 'passing_project').latest_revision
    SourceControl::Subversion.new(:path => 'foo', :repository => fixture_repository_url).latest_revision
    assert_raise(Errno::ENOENT) { SourceControl::Subversion.new(:path => 'foo').latest_revision }
  end
  
  def test_up_to_date
    checkout 'passing_project', :revision => 2

    expected_reasons = 
"New revision 29 detected
Revision 29 committed by bguthrie on 2011-03-31 02:03:31
Updated passing test to use assert_equal instead of assert, which does not work properly under Ruby 1.9.2.
  M /passing_project/passing_test.rb

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
    
    assert @svn.up_to_date?(reasons = [], 29)
    assert_equal "", reasons.join("\n")
  end
  
  def xtest_latest_externals_project_is_up_to_date
    checkout 'project_with_externals'
    
    assert @svn.up_to_date?
  end
  
  def xtest_up_to_date_is_false_on_project_with_missing_externals_in_local_copy
    checkout 'project_with_externals'
    FileUtils.rm_rf 'project_with_externals/external_path'
    
    assert_false @svn.up_to_date?
    
    # FIXME This fails because the external SVN repo is hosted on Rubyforge and no longer active. Need a new repo.
    # @svn.update
    # assert @svn.up_to_date?
  end
  
  def xtest_svn_update_makes_up_to_date_true_for_project_with_externals
    checkout 'project_with_externals', :revision => 27
    
    assert_false @svn.up_to_date?
    
    @svn.update
    
    assert @svn.up_to_date?    
  end
  
  def fixture_repository_url
    repository_path = Rails.root.join("test", "fixtures", "svn-repo")
    urlified_path = repository_path.to_s.sub(/^[a-zA-Z]:/, '').gsub('\\', '/')
    "file://#{urlified_path}"
  end

  def checkout(path, options = {})
    @svn = svn_for(path)
    @svn.checkout options[:revision], io = StringIO.new
  end
  
  def svn_for(path)
    SourceControl::Subversion.new :repository => File.join(fixture_repository_url, path), :path => path
  end
end
