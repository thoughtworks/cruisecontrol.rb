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
      git.expects(:git).with("submodule", ["init"])
      git.expects(:git).with("submodule", ["update"])
      git.update(Git::Revision.new(:number => '5460c9ea8872745629918986df7238871f4135ae'))
    end
  end

  def test_update_with_no_revision
    in_sandbox do
      git = new_git
      git.expects(:git).with("reset", ["--hard"])
      git.expects(:git).with("submodule", ["init"])
      git.expects(:git).with("submodule", ["update"])
      git.update
    end
  end

  def test_up_to_date?_should_return_false_if_there_are_new_revisions
    in_sandbox do
      git = new_git
      mock_revisions(git, [:new_revision])

      reasons = []
      assert_false git.up_to_date?(reasons)
      assert_equal [[:new_revision]], reasons
    end
  end

  def test_up_to_date?_should_return_true_if_there_are_no_new_revisions
    in_sandbox do
      git = new_git
      mock_revisions(git, [])

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
      git.expects(:git).with('fetch', ['origin'])
      git.expects(:git).with("branch").yields(StringIO.new("* master\n"))
      git.expects(:git).with("log", ["-1", '--pretty=raw', "--stat", 'origin/master']).returns('')
      stub_parser = Object.new
      stub_parser.stubs(:parse).returns([:foo])
      Git::LogParser.expects(:new).returns(stub_parser)

      assert_equal :foo, git.latest_revision
    end
  end

  def test_latest_revision_should_timeout
    in_sandbox do
      git = new_git
      class << git
        def git(*args)
          sleep 1
        end
      end
      
      begin
        old_timeout = Configuration.git_load_new_changesets_timeout
        Configuration.git_load_new_changesets_timeout = 0.5

        assert_raise(BuilderError) do
          begin
            git.latest_revision
          rescue BuilderError => e
            assert_equal "Timeout in 'git fetch origin'", e.message
            raise e
          end
        end
      ensure
        Configuration.git_load_new_changesets_timeout = old_timeout
      end
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
  
  def test_watching_for_changes_in_subdirectory
    git = Git.new(:path => '.', :watch_for_changes_in => "subdir")
    one = SourceControl::Git::Revision.new(:number => 1, :changeset => ["a.txt", "diff/sub/b.txt", "some/subdir/c.txt"])
    two = SourceControl::Git::Revision.new(:number => 2, :changeset => ["a.txt", "subdir/b.txt", "subdir/c.txt"])
    three = SourceControl::Git::Revision.new(:number => 3, :changeset => ["subdir/a.txt"])

    mock_revisions(git, [one, two, three])
    
    revisions = git.new_revisions
    assert_equal [two, three], revisions
    assert_equal ["subdir/b.txt", "subdir/c.txt"], revisions[0].files
    assert_equal ["subdir/a.txt"], revisions[1].files
  end

  def new_git(options = {})
    Git.new({:path => "."}.merge(options))
  end

  def mock_revisions(git, revisions)
    git.expects(:git).with("branch").returns("master")
    git.expects(:git).with("fetch", ["origin"])
    git.expects(:git).with("log", ["--pretty=raw", "--stat", "HEAD..origin/master"]).returns("a log output")

    mock_parser = Object.new
    mock_parser.expects(:parse).with("a log output").returns(revisions)
    Git::LogParser.expects(:new).returns(mock_parser)
  end
end