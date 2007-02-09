require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectsTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @svn = FakeSourceControl.new("bob")
    @one = Project.new("one", @svn)
    @two = Project.new("two", @svn)
  end

  def test_load_all
    in_sandbox do |sandbox|
      sandbox.new :file => "one/project_config.rb", :with_content => ""
      sandbox.new :file => "two/project_config.rb", :with_content => ""

      projects = Projects.new(sandbox.root)
      projects.load_all

      assert_equal("one", projects[0].name)

      assert_equal("two", projects[1].name)
    end
  end

  def test_add
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one
      projects << @two

      projects = Projects.new(sandbox.root)
      projects.load_all

      assert_equal("one", projects[0].name)
      assert_equal("two", projects[1].name)
    end
  end

  def test_add_checks_out_fresh_project
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)

      projects << @one

      assert file('one/work').exists?
      assert file('one/work/README').exists?
    end
  end

  def test_add_cleans_up_after_itself_if_svn_throws_exception
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      @svn.expects(:checkout).raises("svn error")

      assert_raises('svn error') do
        projects << @one
      end

      assert !file('one/work').exists?
      assert !file('one').exists?
    end
  end

  def test_can_not_add_project_with_same_name
    in_sandbox do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one      
      assert_raises('project named "one" already exists') do
        projects << @one        
      end
      assert File.directory?(@one.path), "Project directory does not exist."
    end
  end

  def test_load_project
    in_sandbox do |sandbox|
      sandbox.new :file => 'one/project_config.rb', :with_content => ''

      new_project = Projects.load_project(File.join(sandbox.root, 'one'))

      assert_equal('one', new_project.name)
      assert_equal(File.join(sandbox.root, 'one'), new_project.path)
    end
  end

  def test_load_project_with_no_config
    in_sandbox do |sandbox|
      sandbox.new :file => "myproject/builds-1/__success__"

      new_project = Projects.load_project(sandbox.root + '/myproject')

      assert_equal("myproject", new_project.name)
      assert_equal(Subversion, new_project.source_control.class)
      assert_equal(sandbox.root + "/myproject", new_project.path)
    end
  end

  def test_each
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