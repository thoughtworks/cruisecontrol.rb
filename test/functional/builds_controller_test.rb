require File.dirname(__FILE__) + '/../test_helper'
require 'builds_controller'

# Re-raise errors caught by the controller.
class BuildsController
  attr_accessor :load_projects
  def rescue_action(e) raise end
end

class BuildsControllerTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @controller = BuildsController.new
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

  def test_show_with_build
    @sandbox.new :file => "two/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-25/build_status.pingpong"

    get :show, :project => 'two'

    assert_equal @two, assigns(:project)
    assert_equal '25', assigns(:build).label
  end

  def test_show_specific_build
    @sandbox.new :file => "two/build-24/build_status.pingpong"
    @sandbox.new :file => "two/build-25/build_status.pingpong"

    get :show, :project => 'two', :build => 24

    assert_equal @two, assigns(:project)
    assert_equal '24', assigns(:build).label
  end

  def test_show_with_no_build
    get :show, :project => "two"

    assert_response :success

    assert_equal @two, assigns(:project)
    assert_nil assigns(:build)
    assert_template 'no_builds_yet'
  end

  def new_project(name)
    project = Project.new(name, Subversion.new)
    project.path = file(name).name
    project.add_plugin(EmailNotifier.new)
    project
  end
  
  def test_artifacts_as_html
    @sandbox.new :file => 'two/build-1/build_status.pingpong'
    @sandbox.new :file => 'two/build-1/rcov/index.html', :with_contents => 'apple pie'
    
    get :artifact, :project => 'two', :build => '1', :artifact_path => ['rcov', 'index.html']
    
    assert_equal 'apple pie', @response.body
    assert_equal 'text/html', @response.headers['Content-Type']
  end
  
  def test_artifacts_get_right_mime_types
    @sandbox.new :file => 'two/build-1/build_status.pingpong'

    assert_type 'foo.jpg',  'image/jpeg'
    assert_type 'foo.jpeg', 'image/jpeg'
    assert_type 'foo.png',  'image/png'
    assert_type 'foo.gif',  'image/gif'
    assert_type 'foo.html', 'text/html'
    assert_type 'foo.css',  'text/css'
    assert_type 'foo.js',   'text/javascript'
    assert_type 'foo.txt',  'text/plain'
    assert_type 'foo',      'text/plain'  # none
    assert_type 'foo.asdf', 'text/plain'  # unknown
  end
  
  def assert_type(file, type)
    @sandbox.new :file => "two/build-1/#{file}", :with_content => 'lemon'
    
    get :artifact, :project => 'two', :build => '1', :artifact_path => file
    
    assert_equal 'lemon', @response.body
    assert_equal type, @response.headers['Content-Type']
  end
  
  # secure
end