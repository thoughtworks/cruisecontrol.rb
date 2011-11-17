require 'test_helper'

class GitIntegrationTest < ActiveSupport::TestCase
  include FileSandbox
  
  # Git in the sandbox
  # CC.rb is tracked in a git repository, configured to ignore the __sandbox
  # directory.  To be able to properly test some aspects of git integration
  # we need access to a git repository we can manipulate in the sandbox.
  # To achieve this, we initialize a git repository in the sandbox, then operate
  # on it using the --git-dir/--work-tree options to ensure we're not interfering
  # with the CC.rb repository.
    
  def test_clean_checkout_should_not_remove_tracked_files
    with_sandboxed_git do |proj_dir, git|
      tracked_file = File.join(proj_dir, 'tracked.txt')
      FileUtils.touch tracked_file
      sandbox_git_add_and_commit(proj_dir, File.basename(tracked_file))
      untracked_file = File.join(proj_dir, 'untracked.txt')
      git.clean_checkout
      assert File.exist? tracked_file
      assert_false File.exist? untracked_file
    end
  end 
  
  def test_clean_checkout_should_remove_untracked_directories
    with_sandboxed_git do |proj_dir, git|
      untracked_dirs = File.join(proj_dir, 'untracked/by/git')
      FileUtils.mkdir_p untracked_dirs
      git.clean_checkout
      assert_false File.directory? untracked_dirs
    end
  end
  
  def test_clean_checkout_should_remove_untracked_files 
    with_sandboxed_git do |proj_dir, git|
      untracked_file = File.join(proj_dir, 'untracked.txt')
      FileUtils.touch untracked_file
      git.clean_checkout
      assert_false File.exist? untracked_file
    end
  end
  
  def with_sandboxed_git(proj_name = 'test_project', options = {}, &block)
    in_sandbox do |sandbox|
      proj_dir = File.join(sandbox.root, proj_name)
      FileUtils.mkdir proj_dir
      git = SourceControl::Git.new(:path => proj_dir)
      git_init(proj_dir)
      block.call(proj_dir, git)
    end
  end
  
  def sandbox_git_add_and_commit(proj_dir, file_name, message=nil)
    sandbox_git_add(proj_dir, file_name)
    sandbox_git_commit(proj_dir, file_name, (message || "Added #{file_name}"))
  end
  
  def sandbox_git_add(proj_dir, file_name)
    sandbox_git_files_must_exist(proj_dir, file_name)
    %x[git --git-dir=#{proj_dir}/.git --work-tree=#{proj_dir}/ add #{file_name}]
  end
  
  def sandbox_git_commit(proj_dir, file_name, message)
    sandbox_git_files_must_exist(proj_dir, file_name)
    %x[git --git-dir=#{proj_dir}/.git --work-tree=#{proj_dir}/ commit #{file_name} -m #{message}]
  end
  
  def git_init(path)
    %x[git init #{path}]
  end  
  
  def sandbox_git_files_must_exist(proj_dir, file_name)
    unless(File.exist?(File.join(proj_dir, file_name)))
      raise "The specified file [#{file_name}] does not exist in the sandbox.  
              You must specify file names relative to the project directory [#{proj_dir}] in the sandbox."
    end
  end
end
