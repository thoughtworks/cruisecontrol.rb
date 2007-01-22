require File.dirname(__FILE__) + '/../test_helper'

class IntegrationTest < Test::Unit::TestCase
  include FileSandbox

  def test_checkout
    # with_project calls svn.checkout
    with_project 'passing_project' do |project, sandbox, svn|
      assert File.exists?("passing_project/work/passing_test.rb")
    end
  end

  def test_new_revisions
    with_project('passing_project', :revision => 2) do |project, sandbox, svn|
      expected_revisions = [
          Revision.new(3, 'averkhov', DateTime.new(2007, 01, 11, 14, 01, 43, Rational(-7, 24)),
                       'another revision',
                       [ChangesetEntry.new('M', '/passing_project/revision_label.txt')]),
          Revision.new(4, 'averkhov', DateTime.new(2007, 01, 11, 14, 02, 03, Rational(-7, 24)),
                       'and one more revision, for good measure',
                       [ChangesetEntry.new('M', '/passing_project/revision_label.txt')]),
          Revision.new(7, 'averkhov', DateTime.new(2007, 01, 12, 18, 05, 26, Rational(-7, 24)),
                       'Making both revision labels up to date',
                       [ChangesetEntry.new('M', '/failing_project/revision_label.txt'),
                        ChangesetEntry.new('M', '/passing_project/revision_label.txt')])
          ]
      assert_equal expected_revisions, svn.revisions_since(project, 2)
    end
  end

  def test_new_revisions_should_return_an_empty_array_for_uptodate_local_copy
    with_project 'passing_project' do |project, sandbox, svn|
      assert_equal [],  svn.revisions_since(project, 7)
    end
  end

#  def test_build_new_checkin
#    with_project('passing_project', :revision => 2) do |project, sandbox, svn|
#
#      assert_equal '2', File.read("#{sandbox.root}/passing_project/work/revision_label.txt").chomp
#
#      result = project.build_new_checkin
#
#      assert result.is_a?(Build)
#
#      assert_equal true, result.successful?
#
#      assert File.exists?("#{sandbox.root}/passing_project/build-7/build_status = success")
#      assert File.exists?("#{sandbox.root}/passing_project/build-7/changeset.log")
#      assert File.exists?("#{sandbox.root}/passing_project/build-7/build.log")
#    end
#  end

  def test_build_new_checkin_for_a_failling_build
    with_project('failing_project', :revision => 6) do |project, sandbox, svn|
      result = project.build_if_necessary

      assert result.is_a?(Build)
      assert_equal true, result.failed?

      assert file("failing_project/build-7/build_status = failed").exists?
      assert_equal false, file("failing_project/build-7/build_status = success").exists?

      assert file("failing_project/build-7/changeset.log").exists?
      assert file("failing_project/build-7/build.log").exists?
    end
  end

  def test_build_if_necessary_should_return_nil_when_no_changes_were_made
    with_project 'passing_project' do |project, sandbox, svn|
      sandbox.new :file=>'passing_project/build-7/build_status = success'
      result = project.build_if_necessary
      assert_nil result
      # test existence and contents of log files
    end
  end

  def fixture_repository_url
    repository_path = File.expand_path("#{RAILS_ROOT}/test/fixtures/svn-repo")
    urlified_path = repository_path.sub(/^[a-zA-Z]:/, '').gsub('\\', '/')
    "file://#{urlified_path}"
  end

  def with_project(project_name, options = {}, &block)
    in_sandbox do |sandbox|
      svn = Subversion.new :url => "#{fixture_repository_url}/#{project_name}"
      svn.checkout "#{sandbox.root}/#{project_name}/work", options[:revision]
      
      project = Project.new('passing_project', svn, "#{sandbox.root}/#{project_name}/work")
      project.path = "#{sandbox.root}/#{project_name}"
      
      block.call(project, sandbox, svn)
    end
  end
end