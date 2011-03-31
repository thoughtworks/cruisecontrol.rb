require 'test_helper'

class DocumentationControllerTest < ActionController::TestCase

  def test_documentation
    get :get, :path => []
    assert_response :success
    
    get :get, :path => 'docs'
    assert_response :success
    assert_template 'documentation/docs'
    
    assert_raise ActionView::MissingTemplate do
      get :get, :path => 'bad_request'
    end
  end
  
  def test_plugins
    get :plugins, :type => 'installed', :name => 'builder_status.rb'
    assert_response :success
  end

end
