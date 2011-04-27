require 'test_helper'

require 'rexml/document'
require 'rexml/xpath'

class ProjectsControllerTest < ActionController::TestCase
  include FileSandbox
  include BuildFactory

  def test_index_rhtml  
    p1 = create_project_stub('one', 'success')
    p2 = create_project_stub('two', 'failed', [create_build_stub('1', 'failed')])
    Project.expects(:all).returns([p1, p2])
    stub_change_set_parser
    
    get :index
    assert_response :success
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end
  
  def test_index_rjs
    Project.expects(:all).returns([create_project_stub('one'), create_project_stub('two')])
    
    post :index, :format => 'js'

    assert_response :success
    assert_template 'index_js'
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
  end

  def test_index_rss
    Project.expects(:all).returns([
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
    Project.expects(:all).returns([
        create_project_stub('one', 'success', [create_build_stub('1', 'success')]),
        create_project_stub('two', 'incomplete', [create_build_stub('10', 'failed'), create_build_stub('11', 'incomplete')])
        ])
    post :index, :format => 'rss'
    
    xml = REXML::Document.new(@response.body)
    assert_equal "two build 10 failed", REXML::XPath.first(xml, '/rss/channel/item[2]/title').text
  end
  
  def test_should_be_able_to_provide_rss_for_single_project
    Project.expects(:find).with('one').returns(create_project_stub('one', 'success', [create_build_stub('10', 'success')]))
    get :show, :id => 'one', :format => 'rss'
    assert_response :success
    assert_template 'show_rss'
    
    xml = REXML::Document.new(@response.body)
    assert_equal "one build 10 success", REXML::XPath.first(xml, '/rss/channel/item[1]/title').text
  end

  def test_dashboard_should_have_link_to_single_project
    Project.expects(:all).returns([create_project_stub('one', 'success')])
    get :index
    assert_tag :tag => "a", :attributes => {:href => /\/projects\/one/}, :content => "one"
  end
  
  def test_dashboard_should_have_button_to_start_builder_if_builder_is_down
    project = create_project_stub('one', 'success')
    Project.stubs(:all).returns([project])
    
    project.stubs(:builder_state_and_activity).returns("builder_down")
    get :index
    assert_tag :tag => "button", :content => /Start Builder/

    project.stubs(:builder_state_and_activity).returns("sleeping")
    get :index
    assert_tag :tag => "button", :content => /Build Now/
  end

  def test_show_action_with_html_format_should_redirect_to_builds_show
    stub_project = Object.new
    Project.expects(:find).with('one').returns(stub_project)
    get :show, :id => 'one'
    assert_response :redirect
    assert_redirected_to :controller => "builds", :action => "show", :project => stub_project
  end

  def test_index_cctray
    Project.expects(:all).returns([
        create_project_stub('one', 'success', [create_build_stub('10', 'success')]),
        create_project_stub('two')])

    get :index, :format => 'cctray'

    assert_response :success
    assert_template 'index_cctray'
    assert_equal %w(one two), assigns(:projects).map { |p| p.name }
    
    xml = REXML::Document.new(@response.body)

    first_project = REXML::XPath.first(xml, '/Projects/Project[1]]')
    second_project = REXML::XPath.first(xml, '/Projects/Project[2]]')  

    assert_equal 'one', first_project.attributes['name']
    assert_equal 'Success', first_project.attributes['lastBuildStatus']
    assert_equal '10', first_project.attributes['lastBuildLabel']
    assert_equal 'Building', first_project.attributes['activity']
    assert_equal 'http://test.host/projects/one', first_project.attributes['webUrl']

    assert_equal 'two', REXML::XPath.first(xml, '/Projects/Project[2]]').attributes['name']
  end

  def test_index_cctray_should_exclude_incomplete_build
    Project.expects(:all).returns([
        create_project_stub('one', 'failed', [create_build_stub('10', 'failed'), create_build_stub('11', 'incomplete')])
        ])

    post :index, :format => 'cctray'

    xml = REXML::Document.new(@response.body)
    assert_equal 'one', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['name']
    assert_equal 'Failure', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['lastBuildStatus']
    assert_equal '10', REXML::XPath.first(xml, '/Projects/Project[1]').attributes['lastBuildLabel']
    assert_equal 'Building', REXML::XPath.first(xml, '/Projects/Project[1]]').attributes['activity']
  end


  def test_code
    in_sandbox do |sandbox|
      project = create_project "three"
      sandbox.new :file => 'projects/three/work/app/controller/FooController.rb', :with_contents => "class FooController\nend\n"
    
      get :code, :id => 'three', :path => ['app', 'controller', 'FooController.rb'], :line => 2

      assert_response :success
      assert_match /class FooController/, @response.body
    end
  end

  def test_code_url_not_fully_specified
    Project.expects(:find).never

    get :code, :path => ['foo'], :line => 1
    assert_response 404
    assert_equal 'Project not specified', @response.body

    get :code, :id => 'foo', :line => 1
    assert_response 404
    assert_equal 'Path not specified', @response.body
  end

  def test_code_non_existant_project
    Project.expects(:find).with('foo').returns(nil)
    get :code, :id => 'foo', :path => ['foo.rb'], :line => 1
    assert_response 404
  end

  def test_code_non_existant_path
    in_sandbox do |sandbox|
      project = create_project "project"

      get :code, :id => 'project', :path => ['foo.rb'], :line => 1
      assert_response 404
    end
  end

  def test_build_should_request_build
    project = create_project_stub('two')
    Project.expects(:find).with('two').returns(project)
    project.expects(:request_build)
    Project.stubs(:all).returns [ project ]
    post :build, :id => "two"
    assert_response :success
    assert_equal 'two', assigns(:project).name
  end
  
  def test_build_non_existant_project
    Project.expects(:find).with('non_existing_project').returns(nil)
    post :build, :id => "non_existing_project"
    assert_response 404
  end
  
  def test_show_unspecified_project
    post :show, :format => 'rss'
    assert_response 404
    assert_equal 'Project not specified', @response.body
  end

  def test_show_non_existant_project
    Project.expects(:find).with('non_existing_project').returns(nil)
    post :show, :id => "non_existing_project", :format => 'rss'
    assert_response 404
    assert_equal 'Project "non_existing_project" not found', @response.body
  end

  def test_should_disable_build_now_button_if_configured_to_do_so
    Configuration.stubs(:disable_build_now).returns(true)
    Project.expects(:all).returns([create_project_stub('one', 'success')])
    get :index
    assert_tag :tag => "button", :attributes => {:onclick => /return false;/}
  end

  def test_should_refuse_build_if_build_now_is_disabled
    Configuration.stubs(:disable_build_now).returns(true)

    get :build, :id => 'one'
    
    assert_response 403
    assert_equal 'Build requests are not allowed', @response.body
  end

  def test_create_adds_a_new_project
    in_sandbox do
      scm = stub("FakeSourceControl")

      FakeSourceControl.expects(:new).returns scm
      Project.expects(:create).with("new_project", scm).returns stub(:id => "some_project")
      post :create, :project => { :name => "new_project", :source_control => { :source_control => "fake_source_control", :repository => "file:///foo" } }
    end
  end

  def test_create_project_redirects_to_project_documentation
    in_sandbox do
      SourceControl.stubs(:create)
      Project.stubs(:create).returns stub(:id => "new_project")

      post :create, :project => { :source_control => {} }
      assert_redirected_to getting_started_project_path("new_project")
    end
  end

  def stub_change_set_parser
    mock = Object.new
    SourceControl::Subversion::ChangesetLogParser.stubs(:new).returns(mock)
    mock.expects(:parse_log).returns([])
  end

end
