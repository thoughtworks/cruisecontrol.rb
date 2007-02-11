require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'
require 'email_notifier'

# Re-raise errors caught by the controller.
class ProjectsController
  attr_accessor :load_projects
  def rescue_action(e) raise end
end

class ProjectsControllerWithFindProjectStubbed < ProjectsController
  attr_accessor :project
  def rescue_action(e) raise end
  
  def find_project(ignored_projects) project end
  def render(ignored_options={});end 
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

  def test_should_refresh_projects_if_builder_and_build_states_tag_changed
    @controller.load_projects = new_project("one"), new_project("two")
    @sandbox.new :file => "one/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-24/build_status.new_status"

    post :refresh_projects, :build_states => 'one:builderdown24pingpong;two:builderdown24old_status;'

    assert_equal [@two], assigns(:projects)   
  end
  
  def test_refresh_projects_should_set_build_states
    @controller.load_projects = new_project("one"), new_project("two")
    @sandbox.new :file => "one/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-24/build_status.new_status"
  
    post :refresh_projects, :build_states => 'one:NotStarted24pingpong;two:NotStarted24old_status;'
  
    assert_equal 'one:builderdown24pingpong;two:builderdown24new_status;', assigns(:build_states)
  end
  
  def test_index_should_set_build_states
    @controller.load_projects = new_project("one"), new_project("two")
    @sandbox.new :file => "one/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-24/build_status.some_status"
  
    get :index
  
    assert_equal 'one:builderdown24pingpong;two:builderdown24some_status;', assigns(:build_states)
  end
  
  def test_should_show_new_added_project_when_refresh_projects
    @sandbox.new :file => "one/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-24/build_status.pingpong"
    @sandbox.new :file => "three/build-24/build_status.pingpong"
  
    post :refresh_projects, :build_states => 'one:builderdown24pingpong;three:builderdown24pingpong;'
  
    assert_equal 'one:builderdown24pingpong;two:builderdown24pingpong;three:builderdown24pingpong;', assigns(:build_states)
    assert_equal [@two], assigns(:new_projects)
    assert_equal [], assigns(:projects)
    assert_equal [], assigns(:deleted_projects)
  end
  
   def test_should_remove_deleted_project_when_refresh_projects
    @controller.load_projects = new_project("one"), new_project("two")
    @sandbox.new :file => "one/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-24/build_status.pingpong"
  
    post :refresh_projects, :build_states => 'one:builderdown24pingpong;two:builderdown24pingpong;three:builderdown24pingpong;'
  
    assert_equal 'one:builderdown24pingpong;two:builderdown24pingpong;', assigns(:build_states)
    assert_equal ['three'], assigns(:deleted_projects)
    assert_equal [], assigns(:projects)
    assert_equal [], assigns(:new_projects)
  end

  def test_should_request_force_build_a_project
    setup_using_controller(ProjectsControllerWithFindProjectStubbed.new)
    @controller.project= @two
    @controller.expects(:redirect_to).times(1).with({:action => :index})
    @two.expects(:request_force_build).times(1).returns("result")
  
    post :force_build, :project => "two" 

    assert_equal "result", flash[:projects_flash]
  end

  def new_project(name)
    project = Project.new(name)
    project.path = "#{@sandbox.root}/#{name}"
    project.add_plugin(EmailNotifier.new)
    project
  end
  
  def create_pid_files_for_projects
    @sandbox.new :file => "one/builder.pid"
    @sandbox.new :file => "two/builder.pid"
    @sandbox.new :file => "three/builder.pid" 
  end
  
  def setup_using_controller(controller)
    @controller = controller
    @controller.load_projects = @projects
  end
end
