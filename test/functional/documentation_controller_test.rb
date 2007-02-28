require File.dirname(__FILE__) + '/../test_helper'
require 'documentation_controller'

# Re-raise errors caught by the controller.
class DocumentationController; def rescue_action(e) raise e end; end

class DocumentationControllerTest < Test::Unit::TestCase
  def setup
    @controller = DocumentationController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_documentation
    get :get, :path => []
    assert_redirected_to :path => 'index.html'
    
    get :get, :path => 'docs.html'
    assert_template 'documentation/docs'
    
    get :get, :path => 'bad_request.html'
    assert_response 404
  end
  
  def test_plugins
    get :plugins, :type => 'installed', :name => 'builder_status.rb'
  end
end
