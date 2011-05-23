require 'test_helper'

class SourceControlTest < Test::Unit::TestCase
  include FileSandbox

  def test_create_should_require_presence_of_url_in_options
    in_sandbox do
      assert_raise(ArgumentError, "options should include repository") do
        scm = SourceControl.create({:repository => nil})
      end
    end
  end 

  def test_create_should_default_to_git
    in_sandbox do
      SourceControl::Git.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo")
    end
  end

  def test_create_should_return_git_adapter_for_git_url
    in_sandbox do
      SourceControl::Git.expects(:new).with(:repository => "git://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "git://my_repo")
    end
  end

  def test_create_should_return_svn_adapter_for_svn_url
    in_sandbox do
      SourceControl::Subversion.expects(:new).with(:repository => "svn://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "svn://my_repo")
    end
  end

  def test_create_should_return_svn_adapter_for_svn_ssh_url
    in_sandbox do
      SourceControl::Subversion.expects(:new).with(:repository => "svn+ssh://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "svn+ssh://my_repo")
    end
  end

  def test_create_should_return_a_git_instance_if_asked_to_do_so
    in_sandbox do
      SourceControl::Git.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo", :source_control => 'git')
    end
  end

  def test_create_should_return_a_subversion_instance_if_asked_to_do_so
    in_sandbox do
      SourceControl::Subversion.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo", :source_control => 'subversion')
    end
  end

  def test_create_should_return_a_subversion_instance_if_asked_to_do_so_in_abbreviated_way
    in_sandbox do
      SourceControl::Subversion.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo", :source_control => 'svn')
    end
  end

  def test_create_should_return_mercurial_adapter_if_asked_to_do_so
    in_sandbox do
      SourceControl::Mercurial.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo", :source_control => 'mercurial')
    end
  end

  def test_create_should_return_mercurial_adapter_if_asked_to_do_so_in_abbreviated_way
    in_sandbox do
      SourceControl::Mercurial.expects(:new).with(:repository => "http://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "http://my_repo", :source_control => 'hg')
    end
  end

  def test_create_should_blow_up_if_given_a_non_recognized_source_control_string
    in_sandbox do
      assert_raise RuntimeError do
        SourceControl.create(:repository => "http://my_repo", :source_control => 'not_a_scm')
      end
    end
  end

  def test_create_should_blow_up_if_given_class_that_can_be_constantized_but_is_not_a_scm_adapter
    in_sandbox do
      assert_raise RuntimeError do
        SourceControl.create(:repository => "http://my_repo", :source_control => "String")
      end
    end
  end

  def test_create_should_return_adapter_according_to_scm_type_when_it_contradicts_url
    in_sandbox do
      SourceControl::Subversion.expects(:new).with(:repository => "git://my_repo").returns(:foo)
      assert_equal :foo, SourceControl.create(:repository => "git://my_repo", :source_control => 'svn')
    end
  end

  def test_detect_should_identify_git_repository_by_presence_of_dotgit_directory
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(true)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(false)
      SourceControl::Git.expects(:new).with(:path => './Proj1/work').returns(:git_instance)

      assert_equal :git_instance, SourceControl.detect('./Proj1/work')
    end
  end

  def test_detect_should_identify_mercurial_repository_by_presence_of_dothg_directory
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(true)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(false)
      SourceControl::Mercurial.expects(:new).with(:path => './Proj1/work').returns(:hg_instance)

      assert_equal :hg_instance, SourceControl.detect('./Proj1/work')
    end
  end

  def test_detect_should_identify_subversion_repository_by_presence_of_dotsvn_directory
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(true)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(false)
      SourceControl::Subversion.expects(:new).with(:path => './Proj1/work').returns(:svn_instance)

      assert_equal :svn_instance, SourceControl.detect('./Proj1/work')
    end
  end

  def test_detect_should_identify_bazaar_repository_by_presence_of_dotbzr_directory
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(true)
      SourceControl::Bazaar.expects(:new).with(:path => './Proj1/work').returns(:bzr_instance)

      assert_equal :bzr_instance, SourceControl.detect('./Proj1/work')
    end
  end


  def test_detect_should_blow_up_if_there_is_neither_subversion_nor_git
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(false)

      assert_raise RuntimeError, "Could not detect the type of source control in ./Proj1/work" do
        SourceControl.detect('./Proj1/work')
      end
    end
  end

  def test_detect_should_blow_up_if_there_is_both_subversion_and_git
    in_sandbox do
      File.expects(:directory?).with(File.join('./Proj1/work', '.git')).returns(true)
      File.expects(:directory?).with(File.join('./Proj1/work', '.svn')).returns(true)
      File.expects(:directory?).with(File.join('./Proj1/work', '.hg')).returns(false)
      File.expects(:directory?).with(File.join('./Proj1/work', '.bzr')).returns(false)

      assert_raise RuntimeError, "More than one type of source control was detected in ./Proj1/work" do
        SourceControl.detect('./Proj1/work')
      end
    end
  end

end
