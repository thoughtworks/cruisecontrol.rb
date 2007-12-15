require File.dirname(__FILE__) + '/../test_helper'
require 'builds_controller'

# Re-raise errors caught by the controller.
class BuildsController
  def rescue_action(e) raise end
end

class BuildsControllerTest < Test::Unit::TestCase
  include FileSandbox
  include BuildFactory

  def setup
    @controller = BuildsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show
    with_sandbox_project do |sandbox, project|
      create_builds 24, 25

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
      create_builds 23, 24, 25

      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name, :build => 24

      assert_response :success
      assert_template 'show'
      assert_equal project, assigns(:project)
      assert_equal '24', assigns(:build).label
      
      assert_tag :tag => 'a', 
                 :content => 'next >',
                 :attributes => {:href => /\/builds\/#{project.name}\/25/}

      assert_tag :tag => 'a', 
                 :content => '< prev',
                 :attributes => {:href => /\/builds\/#{project.name}\/23/}

      assert_tag :tag => 'a', 
                 :content => 'latest >>',
                 :attributes => {:href => /\/builds\/#{project.name}/}
    end
  end

  def test_show_only_30_builds
    with_sandbox_project do |sandbox, project|
      create_builds *(1..50)
      Projects.stubs(:find).with(project.name).returns(project)
      
      get :show, :project => project.name
      assert_tag :tag => 'a', :content => /30 \(.*\)/
      assert_no_tag :tag => 'a', :content => /11 \(.*\)/
    end
  end
  
  def test_drop_down_list_for_older_builds
    with_sandbox_project do |sandbox, project|
      create_builds *(1..50)
      Projects.stubs(:find).with(project.name).returns(project)

      get :drop_down, :format => 'js', :project => project.name
      assert_tag :tag => "option", :parent => {:tag => "select"}, :content => /11 \(.*\)/
      assert_tag :tag => "option", :content => "Older Builds..."

      get :drop_down, :format => 'js', :project => project.name, :build => "11"
      assert_tag :tag => "option", :content => /11 \(.*\)/
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

  def test_show_unknown_build
    with_sandbox_project do |sandbox, project|
      create_build 1
      Projects.expects(:find).with(project.name).returns(project)

      get :show, :project => project.name, :build => 2

      assert_response 404
      assert_equal 'Build "2" not found', @response.body
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
      create_build 1
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
      create_build 1

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
      create_build 1

      Projects.expects(:find).with(project.name).returns(project)

      get :artifact, :project => project.name, :build => '1', :path => 'foo'
      assert_response 404
    end
  end
  
  def test_artifact_is_directory
    with_sandbox_project do |sandbox, project|
      create_build 1
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
        :title => "#{project.name} builds"}
    end    
  end

  def test_should_autorefresh_incomplete_builds
    with_sandbox_project do |sandbox, project|
      sandbox.new :directory => 'build-1-success'
      sandbox.new :directory => 'build-2'
    
      Projects.stubs(:find).with(project.name).returns(project)

      assert project.last_build.incomplete?
      
      get :show, :project => project.name, :build => '1'
      assert !assigns(:autorefresh)
      
      get :show, :project => project.name, :build => '2'
      assert assigns(:autorefresh)
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