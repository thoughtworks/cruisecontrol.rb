require 'test_helper'

class DocumentationControllerTest < ActionController::TestCase

  context "GET /documentation" do
    test "should render properly without a given path" do
      get :get
      assert_response :success
    end
  end

  context "GET /documentation/*:path" do
    test "should render the requested documentation path" do
      get :get, :path => 'docs'
      assert_response :success
      assert_template 'documentation/docs'
    end
    
    test "should render a 404 if the requested path does not exist" do
      assert_raise ActionView::MissingTemplate do
        get :get, :path => 'bad_request'
      end
    end
  end

  context "GET /documentation/plugins" do
    test "should render the plugins template successfully" do
      get :plugins, :type => 'installed', :name => 'builder_status.rb'
      assert_response :success
    end
  end

end
