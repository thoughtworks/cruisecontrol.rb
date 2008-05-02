require File.dirname(__FILE__) + '/../../test_helper'
require 'stringio'

class SourceControl::GitTest < Test::Unit::TestCase

  include FileSandbox
  include SourceControl

  def test_initialize_should_remember_url
    git = Git.new(:url => "git:/my_repo")
    assert_equal "git:/my_repo", git.url
  end

  def test_checkout_should_perform_git_clone
    in_sandbox do
      git = new_git(:url => "git:/my_repo")
      git.expects(:git).with("clone", ["git:/my_repo", '.'])
      git.checkout
    end
  end

  def test_checkout_should_blow_up_when_url_was_not_given_to_the_ctor
    in_sandbox do
      git = Git.new(:url => nil)
      git.expects(:git).never

      assert_raises(RuntimeError) { git.checkout }
    end
  end

  def new_git(options)
    Git.new({:path => "."}.merge(options))
  end

end