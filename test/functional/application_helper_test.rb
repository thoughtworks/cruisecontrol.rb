require File.dirname(__FILE__) + '/../test_helper'
require 'builds_controller'

class ApplicationHelperTest < Test::Unit::TestCase
  include ApplicationHelper
  
  def test_format_time_humane
      Time.stubs(:now).returns(Time.parse('2007-01-03 03:00:00'))

      # before this year
      assert_equal '31 Dec 06', format_time(Time.parse('2006-12-31 23:59:59'), :human)

      # this year, before today
      assert_equal '1 Jan', format_time(Time.parse('2007-01-01 00:00:00'), :human)
      assert_equal '2 Jan', format_time(Time.parse('2007-01-02 23:59:59'), :human)

      # today
      assert_equal '0:00', format_time(Time.parse('2007-01-03 00:00:00'), :human)
      assert_equal '0:01', format_time(Time.parse('2007-01-03 00:01:00'), :human)
      assert_equal '1:02', format_time(Time.parse('2007-01-03 01:02:00'), :human)
      assert_equal '1:02', format_time(Time.parse('2007-01-03 01:02:59'), :human)
      assert_equal '9:59', format_time(Time.parse('2007-01-03 9:59:59'), :human)
      assert_equal '10:00', format_time(Time.parse('2007-01-03 10:00:00'), :human)
      assert_equal '23:59', format_time(Time.parse('2007-01-03 23:59:59'), :human)

      # after today
      assert_equal '2007-01-04 00:00:00', format_time(Time.parse('2007-01-04 00:00:00 ?future?'))      
  end

end