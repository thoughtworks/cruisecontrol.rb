require File.dirname(__FILE__) + '/../../test_helper'
require 'stringio'

class SourceControl::GitTest < Test::Unit::TestCase

  include FileSandbox
  include SourceControl

  def test_checkout_with_revision_given
    in_sandbox do
      git = new_git(:repository => "git:/my_repo")
      git.expects(:git).with("clone", ["git:/my_repo", '.'], :execute_in_project_directory => false)
      git.expects(:git).with("reset", ['--hard', '5460c9ea8872745629918986df7238871f4135ae'])
      git.checkout(Git::Revision.new(:number => '5460c9ea8872745629918986df7238871f4135ae'))
    end
  end

  def test_update
    in_sandbox do
      git = new_git
      git.expects(:git).with("reset", ["--hard", '5460c9ea8872745629918986df7238871f4135ae'])
      git.update(Git::Revision.new(:number => '5460c9ea8872745629918986df7238871f4135ae'))
    end
  end

  def test_update_with_no_revision
    in_sandbox do
      git = new_git
      git.expects(:git).with("reset", ["--hard"])
      git.update
    end
  end

  def test_up_to_date?_should_return_false_if_there_are_new_revisions
    in_sandbox do
      git = new_git
      git.expects(:git).with("remote", ["update"])
      git.expects(:git).with("log", ["--pretty=raw", "--stat", "HEAD..origin/master"]).returns("a log output")

      mock_parser = Object.new
      mock_parser.expects(:parse).with("a log output").returns([:new_revision])
      Git::LogParser.expects(:new).returns(mock_parser)

      reasons = []
      assert_false git.up_to_date?(reasons)
      assert_equal [[:new_revision]], reasons
    end
  end

  def test_up_to_date?_should_return_true_if_there_are_no_new_revisions
    in_sandbox do
      git = new_git
      git.expects(:git).with("remote", ["update"])
      git.expects(:git).with("log", ["--pretty=raw", "--stat", "HEAD..origin/master"]).returns("\n")

      mock_parser = Object.new
      mock_parser.expects(:parse).with("\n").returns([])
      Git::LogParser.expects(:new).returns(mock_parser)

      assert git.up_to_date?
    end
  end

  
  def test_initialize_should_remember_repository
    git = Git.new(:repository => "git:/my_repo")
    assert_equal "git:/my_repo", git.repository
  end

  def test_checkout_should_perform_git_clone
    in_sandbox do
      git = new_git(:repository => "git:/my_repo")
      git.expects(:git).with("clone", ["git:/my_repo", '.'], :execute_in_project_directory => false)
      git.checkout
    end
  end

  def test_checkout_should_blow_up_when_repository_was_not_given_to_the_ctor
    in_sandbox do
      git = Git.new(:repository => nil)
      git.expects(:git).never

      assert_raises(RuntimeError) { git.checkout }
    end
  end

  def test_latest_revision_should_call_git_log_and_send_it_to_parser
    in_sandbox do
      git = new_git
      git.expects(:git).with("branch").yields(StringIO.new("* master\n"))
      git.expects(:git).with("log", ["-1", '--pretty=raw', "--stat", 'origin/master']).returns('')
      git.expects(:git).with('fetch', ['origin'])
      stub_parser = Object.new
      stub_parser.stubs(:parse).returns([:foo])
      Git::LogParser.expects(:new).returns(stub_parser)

      assert_equal :foo, git.latest_revision
    end
  end

  def test_current_branch_should_parse_git_branch_output
    in_sandbox do
      git = new_git
      branch_output = StringIO.new("* b2\n  master\n")
      git.expects(:git).with('branch').yields(branch_output)
      assert_equal "b2", git.current_branch
    end
  end

  def new_git(options = {})
    Git.new({:path => "."}.merge(options))
  end

end