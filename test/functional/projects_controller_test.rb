require File.dirname(__FILE__) + '/../test_helper'
require File.expand_path(File.dirname(__FILE__) + '/../sandbox')
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController
  attr_accessor :load_projects
  def rescue_action(e) raise end
end

class ProjectsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @sandbox = Sandbox.new
    @projects = new_project("one"), new_project("two"), new_project("three")
    @controller.load_projects = @projects

    @two = @projects[1]
  end

  def teardown
    @sandbox.clean_up
  end

  def test_index
    get :index
    assert_equal @projects, assigns(:projects)
  end

  def test_show_with_build
    @sandbox.new :file => "two/build-24/build_status = pingpong"
    @sandbox.new :file => "two/build-25/build_status = pingpong"

    get :show, :id => 'two'

    assert_equal @two, assigns(:project)
    assert_equal 25, assigns(:build).label
  end

  def test_show_specific_build
    @sandbox.new :file => "two/build-24/build_status = pingpong"
    @sandbox.new :file => "two/build-25/build_status = pingpong"

    get :show, :id => 'two', :build => 24

    assert_equal @two, assigns(:project)
    assert_equal 24, assigns(:build).label
  end

  def test_show_with_no_build
    get :show, :id => "two"

    assert_equal @two, assigns(:project)
    assert_equal Build::NilBuild, assigns(:build).class
  end

  def test_settings
    get :settings, :id => "two"

    assert_equal @two, assigns(:project)
  end

  def test_add_email
    @projects.expects(:save_project).with(@two)

    post :add_email, :id => "two", :value => "jss@gmail.com"

    assert_equal ["jss@gmail.com"], @two.emails

    @projects.verify
  end

  def test_add_remove_email
    @projects.stubs(:save_project)

    post :add_email, :id => "two", :value => "jss@gmail.com"

    assert_equal ["jss@gmail.com"], @two.emails

    post :add_email, :id => "two", :value => "art@gmail.com"
    post :add_email, :id => "two", :value => "stephan@gmail.com"

    assert_equal ["jss@gmail.com", "art@gmail.com", "stephan@gmail.com"], @two.emails

    post :remove_email, :id => "two", :value => "art@gmail.com"

    assert_equal ["jss@gmail.com", "stephan@gmail.com"], @two.emails
  end

#  def test_new
#    get :new_project
#  end
#
#  def test_create
#    get :create_project, :id => "myproject", :source_control => {:type => 'subversion',
#                                                                 :url => "http://svn/myproj",
#                                                                 :username => "foo",
#                                                                 :password => "bar"}
#  end

  private

  def new_project(name)
    project = Project.new(name, Subversion.new)
    project.path = "#{@sandbox.root}/#{name}"
    project
  end
end
