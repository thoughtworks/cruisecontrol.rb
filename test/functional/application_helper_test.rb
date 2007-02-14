require File.dirname(__FILE__) + '/../test_helper'
require 'builds_controller'

class BuildsController
  # Re-raise errors caught by the controller.
  def rescue_action(e) raise end

  # make helper methods available to the controller
  include ApplicationHelper

  # a pseudo-action that passes control to the block and renders nothing
  def test()
    yield
  end
end

class ApplicationHelperTest < Test::Unit::TestCase

  def setup
    @controller = BuildsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_format_time_humane
    Time.stubs(:now).returns(Time.parse('2007-01-03 03:00:00'))

    @controller.test do
      # before this year
      assert_equal '31 Dec 06', @controller.format_time(Time.parse('2006-12-31 23:59:59'), :human)

      # this year, before today
      assert_equal '1 Jan', @controller.format_time(Time.parse('2007-01-01 00:00:00'), :human)
      assert_equal '2 Jan', @controller.format_time(Time.parse('2007-01-02 23:59:59'), :human)

      # today
      assert_equal '0:00', @controller.format_time(Time.parse('2007-01-03 00:00:00'), :human)
      assert_equal '0:01', @controller.format_time(Time.parse('2007-01-03 00:01:00'), :human)
      assert_equal '1:02', @controller.format_time(Time.parse('2007-01-03 01:02:00'), :human)
      assert_equal '1:02', @controller.format_time(Time.parse('2007-01-03 01:02:59'), :human)
      assert_equal '9:59', @controller.format_time(Time.parse('2007-01-03 9:59:59'), :human)
      assert_equal '10:00', @controller.format_time(Time.parse('2007-01-03 10:00:00'), :human)
      assert_equal '23:59', @controller.format_time(Time.parse('2007-01-03 23:59:59'), :human)

      # after today
      assert_equal '2007-01-04 00:00:00', @controller.format_time(Time.parse('2007-01-04 00:00:00 ?future?'))      
    end

  end

end