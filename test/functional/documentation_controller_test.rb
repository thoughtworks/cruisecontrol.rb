require File.dirname(__FILE__) + '/../test_helper'
require 'documentation_controller'

# Re-raise errors caught by the controller.
class DocumentationController; def rescue_action(e) raise e end; end

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
