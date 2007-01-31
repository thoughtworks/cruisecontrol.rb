require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'
require 'email_notifier'

# Re-raise errors caught by the controller.
class ProjectsController
  attr_accessor :load_projects
  def rescue_action(e) raise end
end

class ProjectsControllerTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    setup_sandbox
    @projects = new_project("one"), new_project("two"), new_project("three")
    @controller.load_projects = @projects

    @two = @projects[1]
  end

  def teardown
    teardown_sandbox
  end

  def test_index
    create_pid_files_for_projects
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
  
  def test_update
    @projects.expects(:save_project).with(@two)

    post :update, :id => "two", :project => {:rake_task => 'build', :scheduler => {:polling_interval => 20}}
    
    assert_response :success
    assert_template 'settings'
    assert_equal 'build', @two.rake_task
    assert_equal 20, @two.scheduler.polling_interval
    @projects.verify
  end

  def test_update_rake_task_build_command_precedence
    @projects.stubs(:save_project)

    post :update, :id => "two", :project => {:rake_task => 'build', :build_command => 'ant test'}
    assert_equal nil, @two.rake_task
    assert_equal 'ant test', @two.build_command
    
    post :update, :id => "two", :project => {:rake_task => 'build'}
    assert_equal 'build', @two.rake_task
    assert_equal nil, @two.build_command

    post :update, :id => "two", :project => {:build_command => 'ant test'}
    assert_equal nil, @two.rake_task
    assert_equal 'ant test', @two.build_command
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
    project.path = file(name).name
    project.add_plugin(EmailNotifier.new)
    project
  end
  
  def create_pid_files_for_projects
    @sandbox.new :file => "one/builder.pid"
    @sandbox.new :file => "two/builder.pid"
    @sandbox.new :file => "three/builder.pid" 
  end
end
