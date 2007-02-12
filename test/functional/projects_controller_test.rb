require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController
  def rescue_action(e) raise end
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
  
  def test_code
    in_sandbox do |sandbox|
      project = Project.new('three')
      project.path = sandbox.root
      sandbox.new :file => 'work/app/controller/FooController.rb', :with_contents => "class FooController\nend\n"
      
      Projects.expects(:find).returns(project)
    
      get :code, :project => 'two', :path => ['app', 'controller', 'FooController.rb'], :line => 2
      
      assert_response :success, @response.body
      assert @response.body =~ /class FooController/
    end
  end

  # FIXME merge refresh_projects with index and remake this into test_index_rjs
  def _test_refresh_projects
    Projects.expects(:load_all).returns([create_project_stub('one'), create_project_stub('two')])
    post :refresh_projects

    assert_response :success
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end

  def test_force_build_should_request_force_build
    project = create_project_stub('two')
    Projects.expects(:find).with('two').returns(project)
    project.expects(:request_force_build)
    post :force_build, :project => "two"
    assert_response :success
    assert_equal 'two', assigns(:project).name
  end
  
  def test_force_build_should_assign_nil_if_project_not_found
    Projects.expects(:find).with('non_existing_project').raises("project not found error")
    post :force_build, :project => "non_existing_project"
    assert_response :success
    assert_equal nil, assigns(:project)
  end

end
