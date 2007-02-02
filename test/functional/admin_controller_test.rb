require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController
  def server
    @server ||= Struct.new('StubServer', :save, :load).new(nil)
  end
  
  def rescue_action(e) raise e end
end

class AdminControllerTest < Test::Unit::TestCase
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_email_settings
    ActionMailer::Base.server_settings = {:domain => 'google.com'}
    get :email_settings    
    assert_equal 'google.com', assigns(:email_settings).domain
    assert_equal :no_authentication, assigns(:email_type)
  end

  def test_email_settings_with_gmail
    ActionMailer::Base.server_settings = {:address => 'smtp.gmail.com'}
    get :email_settings
    assert_equal :gmail, assigns(:email_type)
  end

  def test_email_settings_with_gmail_when_no_settings
    ActionMailer::Base.server_settings = {}
    get :email_settings
    assert_equal :gmail, assigns(:email_type)
  end

  def test_email_settings_with_no_authentication
    ActionMailer::Base.server_settings = {:address => 'smtdp.gmail.com', :domain => 'foo.com', :port => 25}
    get :email_settings
    assert_equal :no_authentication, assigns(:email_type)
  end
  
  def test_update_email_settings
    post :update_email_settings, :email_settings => {:address => 'smtp.com', :domain => 'foo.com', :port => '25'}
    
    assert_response :success
    assert_equal 'smtp.com', ActionMailer::Base.server_settings[:address]
    assert_equal 'foo.com', ActionMailer::Base.server_settings[:domain]
    assert_equal '25', ActionMailer::Base.server_settings[:port]
  end
end
