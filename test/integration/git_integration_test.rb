require 'test_helper'

class GitIntegrationTest < ActiveSupport::TestCase
  include FileSandbox
    
  def test_clean_checkout_should_not_remove_tracked_files
    in_sandbox do |sandbox|
      git = SourceControl::Git.new(:path => sandbox.root)
      tracked_file = File.join(sandbox.root, 'tracked.txt')
      FileUtils.touch tracked_file
      git_init(sandbox.root)
      stage(sandbox.root)
      git.clean_checkout
      assert File.exist? tracked_file
    end
  end 
  
  def test_clean_checkout_should_remove_untracked_directories
    in_sandbox do |sandbox|
      git = SourceControl::Git.new(:path => sandbox.root)
      untracked_dirs = File.join(sandbox.root, 'untracked/by/git')
      FileUtils.mkdir_p untracked_dirs
      git_init(sandbox.root)
      git.clean_checkout
      assert_false File.directory? untracked_dirs
    end
  end
  
  def test_clean_checkout_should_remove_untracked_files
    in_sandbox do |sandbox|
      git = SourceControl::Git.new(:path => sandbox.root)
      untracked_file = File.join(sandbox.root, 'untracked.txt')
      FileUtils.touch untracked_file
      git_init(sandbox.root)
      git.clean_checkout
      assert_false File.exist? untracked_file
    end
  end
  
  def git_init(path)
    %x[git init #{path}]
  end
  
  def stage(path)
     %x[git add #{path}]
  end
  
end
