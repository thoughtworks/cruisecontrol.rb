require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'
require 'email_notifier'

# Re-raise errors caught by the controller.
class ProjectsController
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
  end

  def test_index_rhtml
    p1 = create_project_stub('one', 'success')
    p2 = create_project_stub('two', 'failed', [create_build_stub('1', 'failed')])
    Projects.expects(:load_all).returns([p1, p2])

    get :index

    assert_response :success
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end

  # FIXME merge refresh_projects with index and remake this into test_index_rjs
  def _test_refresh_projects
    Projects.expects(:load_all).returns([create_project_stub('one'), create_project_stub('two')])
    post :refresh_projects

    assert_response :success
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end

  def test_force_build
    project = create_project_stub('two')
    Projects.expects(:find).with('two').returns(project)
    project.expects(:request_force_build)

    post :force_build, :project => "two"

    assert_redirected_to :controller => 'projects', :action => 'index'
  end

  def new_project(name)
    project = Projects.new(name)
    project.path = "#{@sandbox.root}/#{name}"
    project.add_plugin(EmailNotifier.new)
    project
  end
  
  def create_project_stub(name, last_build_status = 'failed', last_five_builds = [])
    project = Object.new
    project.stubs(:name).returns(name)
    project.stubs(:last_build_status).returns(last_build_status)
    project.stubs(:last_five_builds).returns(last_five_builds)
    project.stubs(:builder_state_and_activity).returns('building')
    project
  end

  def create_build_stub(label, status, time = Time.at(0))
    build = Object.new
    build.stubs(:label).returns(label)
    build.stubs(:status).returns(status)
    build.stubs(:time).returns(time)
    build.stubs(:failed?).returns(status == 'failed')
    build.stubs(:successful?).returns(status == 'success')
    build
  end

end
