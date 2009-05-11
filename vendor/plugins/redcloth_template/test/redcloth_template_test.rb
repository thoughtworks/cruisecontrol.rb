require 'test/unit'
gem 'actionpack', '>=2.3.0'
require 'action_controller'
require 'action_controller/test_process'

require File.join(File.dirname(__FILE__), '..', 'init')

class TestController < ActionController::Base
  def show
    @title = 'hello'
    render :template => "#{params[:id]}.red", :layout => false
  end
end

TestController.view_paths = [ File.dirname(__FILE__) + '/fixtures/' ]
ActionController::Routing::Routes.reload rescue nil

class RedClothTemplateTest < ActionController::TestCase
  tests TestController

  def test_should_convert_textile_markup_to_html
    get :show, :id => 'textile'
    assert_response :success
    assert_match %r{<h1>hello</h1>}, @response.body
    assert_match %r{<a href="http://example.com/">Link</a>}, @response.body
  end

  def test_should_interpolate_erb_in_template
    get :show, :id => 'erb'
    assert_response :success
    assert_equal "<p>2</p>", @response.body
  end
end
