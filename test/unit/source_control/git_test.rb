require File.dirname(__FILE__) + '/../../test_helper'
require 'stringio'

class SourceControl::GitTest < Test::Unit::TestCase

  include FileSandbox
  include SourceControl

  def test_initialize_should_remember_repository
    git = Git.new(:repository => "git:/my_repo")
    assert_equal "git:/my_repo", git.repository
  end

  def test_checkout_should_perform_git_clone
    in_sandbox do
      git = new_git(:repository => "git:/my_repo")
      git.expects(:git).with("clone", ["git:/my_repo", '.'], :execute_locally => false)
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
      git.expects(:git).with("log", ["-1", '--pretty=raw']).returns('')
      stub_parser = Object.new
      stub_parser.stubs(:parse).returns([:foo])
      Git::LogParser.expects(:new).returns(stub_parser)

      assert_equal :foo, git.latest_revision
    end
  end

  def new_git(options = {})
    Git.new({:path => "."}.merge(options))
  end

end