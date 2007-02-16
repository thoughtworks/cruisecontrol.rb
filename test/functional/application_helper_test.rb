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
       
  def test_format_seconds_general
    assert_equal '0 seconds', format_seconds(0)
    assert_equal '1 second', format_seconds(1)    
    assert_equal '25 seconds', format_seconds(25)
    assert_equal '1 minute', format_seconds(60)
    assert_equal '1 minute', format_seconds(61)    
    assert_equal '33 minutes', format_seconds(2005)
    assert_equal '1 hour', format_seconds(3600)    
    assert_equal '1 hour', format_seconds(3601)
    assert_equal '1 hour 1 minute', format_seconds(3661)    
    assert_equal '2 hours 5 minutes', format_seconds(7500)
    assert_equal '2 hours 5 minutes', format_seconds(7501)    
  end
  
  def test_format_seconds_precise
    assert_equal '0 seconds', format_seconds(0, :precise)
    assert_equal '1 second', format_seconds(1, :precise)    
    assert_equal '25 seconds', format_seconds(25, :precise)
    assert_equal '1 minute', format_seconds(60, :precise)
    assert_equal '1 minute and 1 second', format_seconds(61, :precise)    
    assert_equal '33 minutes and 25 seconds', format_seconds(2005, :precise)
    assert_equal '1 hour', format_seconds(3600, :precise)    
    assert_equal '1 hour and 1 second', format_seconds(3601, :precise)
    assert_equal '1 hour and 1 minute and 1 second', format_seconds(3661, :precise)    
    assert_equal '2 hours and 5 minutes', format_seconds(7500, :precise)
    assert_equal '2 hours and 5 minutes and 1 second', format_seconds(7501, :precise)    
  end
end
