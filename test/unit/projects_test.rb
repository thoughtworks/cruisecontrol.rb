require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../sandbox')

class ProjectsTest < Test::Unit::TestCase

  def setup
    @svn = Subversion.new(:url => "http://rubyforge.org/svn/lemmings", :username => "bob", :password => 'cha')
    @one = Project.new("one", @svn)
    @two = Project.new("two", @svn)
  end

  def test_load_all
    Sandbox.create do |sandbox|
      sandbox.new :file => "one/project_config.rb", :with_content => @one.memento
      sandbox.new :file => "two/project_config.rb", :with_content => @two.memento

      projects = Projects.new(sandbox.root)
      projects.load_all

      assert_equal("one", projects[0].name)
      assert_equal("bob", projects[0].source_control.username)

      assert_equal("two", projects[1].name)
      assert_equal("bob", projects[1].source_control.username)
    end
  end

  def test_add
    Sandbox.create do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one
      projects << @two

      projects = Projects.new(sandbox.root)
      projects.load_all

      assert_equal("one", projects[0].name)
      assert_equal("two", projects[1].name)
    end
  end

  def test_can_not_add_project_with_same_name
    Sandbox.create do |sandbox|
      projects = Projects.new(sandbox.root)
      projects << @one
      assert_raises('project named "one" already exists') do
        projects << @one
      end
    end
  end

  def test_load_project
    Sandbox.create do |sandbox|
      sandbox.new :file => 'one/project_config.rb', :with_content => @one.memento

      new_project = Projects.load_project(File.join(sandbox.root, 'one'))

      assert_equal('one', new_project.name)
      assert_equal('bob', new_project.source_control.username)
      assert_equal(File.join(sandbox.root, 'one'), new_project.path)
    end
  end

  def test_load_project_with_no_config
    Sandbox.create do |sandbox|
      sandbox.new :file => "myproject/builds-1/__success__"

      new_project = Projects.load_project(sandbox.root + '/myproject')

      assert_equal("myproject", new_project.name)
      assert_equal(Subversion, new_project.source_control.class)
      assert_equal(sandbox.root + "/myproject", new_project.path)
    end
  end

  def test_each
    Sandbox.create do |sandbox|
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