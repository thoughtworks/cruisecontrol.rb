require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'
require 'rexml/document'
require 'rexml/xpath'
require 'changeset_log_parser'
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
    stub_change_set_parser
    
    get :index
    assert_response :success
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end
  
  def test_index_rhtml_should_link_to_rss_for_separated_projects
    p1 = create_project_stub('one', 'success')
    Projects.expects(:load_all).returns([p1])

    get :index
    assert_tag :tag => 'a', :attributes => {:href => '/projects/one.rss'},  :child => {:tag => "img", :attributes => {:src => /\/images\/rss.gif/}}
  end
  
  def test_index_rjs
    Projects.expects(:load_all).returns([create_project_stub('one'), create_project_stub('two')])
    
    post :index, :format => 'js'

    assert_response :success
    assert_template 'index_js'
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end

  def test_index_rss
    Projects.expects(:load_all).returns([
        create_project_stub('one', 'success', [create_build_stub('10', 'success')]),
        create_project_stub('two')])

    post :index, :format => 'rss'

    assert_response :success
    assert_template 'index_rss'
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }

    xml = REXML::Document.new(@response.body)
    assert_equal "one build 10 success", REXML::XPath.first(xml, '/rss/channel/item[1]/title').text
    assert_equal "two has never been built", REXML::XPath.first(xml, '/rss/channel/item[2]/title').text
    assert_equal "<pre>bobby checked something in</pre>", REXML::XPath.first(xml, '/rss/channel/item[1]/description').text
    assert_equal "<pre></pre>", REXML::XPath.first(xml, '/rss/channel/item[2]/description').text
  end
  
  def test_rss_should_exclude_incomplete_build
    Projects.expects(:load_all).returns([
        create_project_stub('one', 'success', [create_build_stub('1', 'success')]),
        create_project_stub('two', 'incomplete', [create_build_stub('10', 'failed'), create_build_stub('11', 'incomplete')])
        ])
    post :index, :format => 'rss'
    
    xml = REXML::Document.new(@response.body)
    assert_equal "two build 10 failed", REXML::XPath.first(xml, '/rss/channel/item[2]/title').text
  end
  
  def test_should_be_able_to_provide_rss_for_single_project
    Projects.expects(:find).with('one').returns(create_project_stub('one', 'success', [create_build_stub('10', 'success')]))
    get :show, :id => 'one', :format => 'rss'
    assert_response :success
    assert_template 'show_rss'
    
    xml = REXML::Document.new(@response.body)
    assert_equal "one build 10 success", REXML::XPath.first(xml, '/rss/channel/item[1]/title').text
  end

  def test_dashboard_should_have_link_to_single_project
    Projects.expects(:load_all).returns([create_project_stub('one', 'success')])
    get :index
    assert_tag :tag => "a", :attributes => {:href => /\/projects\/one/}, :content => "one"
  end

  def test_show_action_with_html_format_should_redirect_to_builds_show
    stub_project = Object.new
    Projects.expects(:find).with('one').returns(stub_project)
    get :show, :id => 'one'
    assert_response :redirect
    assert_redirected_to :controller => "builds", :action => "show", :project => stub_project
  end

  def test_index_cctray
    Projects.expects(:load_all).returns([
        create_project_stub('one', 'success', [create_build_stub('10', 'success')]),
        create_project_stub('two')])

    post :index, :format => 'cctray'

    assert_response :success
    assert_template 'index_cctray'
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
    
    xml = REXML::Document.new(@response.body)
    assert_equal 'one', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['name']
    assert_equal 'Success', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['lastBuildStatus']
    assert_equal '10', REXML::XPath.first(xml, '/Projects/Project[1]').attributes['lastBuildLabel']
    assert_equal 'Building', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['activity']
    assert_equal 'two', REXML::XPath.first(xml, '/Projects/Project[2]]').attributes['name']
  end

  def test_code
    in_sandbox do |sandbox|
      project = Project.new('three')
      project.path = sandbox.root
      sandbox.new :file => 'work/app/controller/FooController.rb', :with_contents => "class FooController\nend\n"
      
      Projects.expects(:find).returns(project)
    
      get :code, :project => 'two', :path => ['app', 'controller', 'FooController.rb'], :line => 2
      
      assert_response :success
      assert_match /class FooController/, @response.body
    end
  end

  def test_code_url_not_fully_specified
    Projects.expects(:find).never

    get :code, :path => ['foo'], :line => 1
    assert_response 404
    assert_equal 'Project not specified', @response.body

    get :code, :project => 'foo', :line => 1
    assert_response 404
    assert_equal 'Path not specified', @response.body
  end

  def test_code_non_existant_project
    Projects.expects(:find).with('foo').returns(nil)
    get :code, :project => 'foo', :path => ['foo.rb'], :line => 1
    assert_response 404
  end

  def test_code_non_existant_path
    in_sandbox do |sandbox|
      project = Project.new('project')
      project.path = sandbox.root
      Projects.expects(:find).with('project').returns(project)

      get :code, :project => 'project', :path => ['foo.rb'], :line => 1
      assert_response 404
    end
  end

  def test_build_should_request_build
    project = create_project_stub('two')
    Projects.expects(:find).with('two').returns(project)
    project.expects(:request_build)
    post :build, :id => "two"
    assert_response :success
    assert_equal 'two', assigns(:project).name
  end
  
  def test_build_non_existant_project
    Projects.expects(:find).with('non_existing_project').returns(nil)
    post :build, :id => "non_existing_project"
    assert_response 404
  end
  
  def test_show_unspecified_project
    post :show, :format => 'rss'
    assert_response 404
    assert_equal 'Project not specified', @response.body
  end

  def test_show_non_existant_project
    Projects.expects(:find).with('non_existing_project').returns(nil)
    post :show, :id => "non_existing_project", :format => 'rss'
    assert_response 404
    assert_equal 'Project "non_existing_project" not found', @response.body
  end

  def stub_change_set_parser
    mock = Object.new  
    ChangesetLogParser.stubs(:new).returns(mock)
    mock.expects(:parse_log).returns([])
  end
end
