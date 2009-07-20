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

      assert_raises('svn error') do
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
      assert_raises("Project named \"one\" already exists in #{sandbox.root}") do
        projects << @one        
      end
      assert File.directory?(@one.path), "Project directory does not exist."
    end
  end

  test "Projects.load_project should load the project in the given directory" do
    in_sandbox do |sandbox|
      sandbox.new :file => 'one/cruise_config.rb', :with_content => ''

      new_project = Projects.load_project(File.join(sandbox.root, 'one'))

      assert_equal('one', new_project.name)
      assert_equal(File.join(sandbox.root, 'one'), new_project.path)
    end
  end

  test "Projects.load_project should load a project without any configuration" do
    in_sandbox do |sandbox|
      sandbox.new :directory => "myproject/work/.svn"
      sandbox.new :directory => "myproject/builds-1"

      new_project = Projects.load_project(sandbox.root + '/myproject')

      assert_equal("myproject", new_project.name)
      assert_equal(SourceControl::Subversion, new_project.source_control.class)
      assert_equal(sandbox.root + "/myproject", new_project.path)
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