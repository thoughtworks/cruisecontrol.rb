require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectsTest < ActiveSupport::TestCase
  include FileSandbox

  def setup
    @svn = FakeSourceControl.new("bob")
    @one = Project.new("one", @svn)
    @two = Project.new("two", @svn)
  end

  test "Projects#<< should add a new project" do
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one << @two

      projects = Projects.new(sandbox.root)
      projects.load_all

      assert_equal %w(one two), projects.map(&:name)
    end
  end

  test "Projects#<< should check out an existing project" do
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)

      projects << @one

      assert SandboxFile.new('one/work').exists?
      assert SandboxFile.new('one/work/README').exists?
    end
  end

  test "Projects#<< should clean up after itself if the source control throws an exception" do
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      @svn.expects(:checkout).raises("svn error")

      assert_raise_with_message(RuntimeError, 'svn error') do
        projects << @one
      end

      assert_false SandboxFile.new('one/work').exists?
      assert_false SandboxFile.new('one').exists?
    end
  end

  test "Projects#<< should not allow you to add the same project twice" do
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one      
      assert_raise_with_message(RuntimeError, "Project named \"one\" already exists in #{sandbox.root}") do
        projects << @one        
      end
      assert File.directory?(@one.path), "Project directory does not exist."
    end
  end

  test "Projects#each should allow enumeration over its project list" do
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one << @two

      out = ""
      projects.each do |project|
        out << project.name
      end

      assert_equal("onetwo", out)
    end
  end
end