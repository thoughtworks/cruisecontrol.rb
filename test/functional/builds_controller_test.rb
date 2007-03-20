require File.dirname(__FILE__) + '/../test_helper'
require 'builds_controller'

# Re-raise errors caught by the controller.
class BuildsController
  def rescue_action(e) raise end
end

class BuildsControllerTest < Test::Unit::TestCase
  include FileSandbox

  def setup
    @controller = BuildsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-24/build_status.success"
      sandbox.new :file => "build-25/build_status.success"

      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name

      assert_response :success
      assert_template 'show'
      assert_equal project, assigns(:project)
      assert_equal '25', assigns(:build).label
    end
  end

  def test_show_specific_build
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-24/build_status.pingpong"
      sandbox.new :file => "build-25/build_status.pingpong"

      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name, :build => 24

      assert_response :success
      assert_template 'show'
      assert_equal project, assigns(:project)
      assert_equal '24', assigns(:build).label
      
      assert_tag :tag => 'a', 
                 :content => 'Next Build',
                 :attributes => {:href => /\/builds\/#{project.name}\/25/}

      assert_tag :tag => 'a', 
                 :content => 'Previous Build',
                 :attributes => {:href => /\/builds\/#{project.name}\/24/}

      assert_tag :tag => 'a', 
                 :content => 'Latest Build',
                 :attributes => {:href => /\/builds\/#{project.name}\/25/}
    end
  end

  def test_show_with_no_build
    with_sandbox_project do |sandbox, project|
      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name

      assert_response :success
      assert_template 'no_builds_yet'
      assert_equal project, assigns(:project)
      assert_nil assigns(:build)
    end
  end

  def test_show_no_build
    with_sandbox_project do |sandbox, project|
      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name

      assert_response :success
      assert_template 'no_builds_yet'
      assert_equal project, assigns(:project)
    end
  end

  def test_show_unspecified_project
    get :show

    assert_response 404
    assert_equal 'Project not specified', @response.body
  end

  def test_show_unknown_project
    Projects.expects(:find).with('foo').returns(nil)
    get :show, :project => 'foo'

    assert_response 404
    assert_equal 'Project "foo" not found', @response.body
  end

  def test_artifact_as_html
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => 'build-1/build_status.pingpong'
      sandbox.new :file => 'build-1/rcov/index.html', :with_contents => 'apple pie'

      Projects.expects(:find).with(project.name).returns(project)

      get :artifact, :project => project.name, :build => '1', :path => ['rcov', 'index.html']

      assert_response :success
      assert_equal 'apple pie', @response.body
      assert_equal 'text/html', @response.headers['Content-Type']
    end
  end
  
  def test_artifact_gets_right_mime_types
    with_sandbox_project do |sandbox, project|
      @sandbox, @project = sandbox, project
      sandbox.new :file => 'build-1/build_status.pingpong'

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
  end
  
  def test_artifact_does_not_exist
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => 'build-1/build_status.pingpong'

      Projects.expects(:find).with(project.name).returns(project)

      get :artifact, :project => project.name, :build => '1', :path => 'foo'
      assert_response 404
    end
  end
  
  def test_artifact_is_directory
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => 'build-1/build_status.pingpong'
      sandbox.new :file => 'build-1/foo/index.html'

      Projects.expects(:find).with(project.name).returns(project)

      get :artifact, :project => project.name, :build => '1', :path => 'foo'

      assert_redirected_to :path => ['foo/index.html']
    end
  end

  def test_artifact_bad_request_parameters
    get :artifact, :build => '1', :path => 'foo'
    assert_response 404
    assert_equal 'Project not specified', @response.body

    get :artifact, :project => 'foo', :path => 'foo'
    assert_response 404
    assert_equal 'Build not specified', @response.body

    get :artifact, :project => 'foo', :build => '1'
    assert_response 404
    assert_equal 'Path not specified', @response.body
  end

  def test_artifact_unknown_project
    Projects.expects(:find).with('foo').returns(nil)

    get :artifact, :project => 'foo', :build => '1', :path => 'foo'
    assert_response 404
    assert_equal 'Project "foo" not found', @response.body
  end

  def test_artifact_unknown_build
    mock_project = Object.new
    Projects.expects(:find).with('foo').returns(mock_project)
    mock_project.expects(:find_build).with('1').returns(nil)

    get :artifact, :project => 'foo', :build => '1', :path => 'foo'
    assert_response 404
    assert_equal 'Build "1" not found', @response.body
  end
  
  def test_should_link_rss_for_just_this_project
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => 'build-1/build_status.pingpong'
    
      Projects.expects(:find).with(project.name).returns(project)
      get :show, :project => project.name
      assert_tag :tag => "link", :attributes => {
        :href => /\/projects\/#{project.name}.rss/, 
        :title => "RSS feed"}
    end    
  end

  def assert_type(file, type)
    @sandbox.new :file => "build-1/#{file}", :with_content => 'lemon'

    Projects.expects(:find).with(@project.name).returns(@project)

    get :artifact, :project => @project.name, :build => '1', :path => file

    assert_response :success
    assert_equal 'lemon', @response.body
    assert_equal type, @response.headers['Content-Type']
  end

end