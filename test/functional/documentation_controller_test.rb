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

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
