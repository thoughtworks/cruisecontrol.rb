require 'test_helper'

class TimeFormatterTest < Test::Unit::TestCase
  def test_formats_last_year_human
    Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
    assert_equal '31 Dec 08', TimeFormatter.new(Time.parse('2008-12-31 23:59:59')).human
  end

  def test_formats_this_year_before_today_human
    Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
    assert_equal '1 Jun',  TimeFormatter.new(Time.parse('2009-06-01 00:00:00')).human
    assert_equal '30 Jun', TimeFormatter.new(Time.parse('2009-06-30 23:59:59')).human
  end

  def test_formats_today_human
    Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
    assert_equal '0:00',  TimeFormatter.new(Time.parse('2009-07-01 00:00:00')).human
    assert_equal '0:01',  TimeFormatter.new(Time.parse('2009-07-01 00:01:00')).human
    assert_equal '1:02',  TimeFormatter.new(Time.parse('2009-07-01 01:02:00')).human
    assert_equal '1:02',  TimeFormatter.new(Time.parse('2009-07-01 01:02:59')).human
    assert_equal '9:59',  TimeFormatter.new(Time.parse('2009-07-01 09:59:59')).human
    assert_equal '10:00', TimeFormatter.new(Time.parse('2009-07-01 10:00:00')).human
    assert_equal '23:59', TimeFormatter.new(Time.parse('2009-07-01 23:59:59')).human
  end

  def test_formats_future_human
    Time.stubs(:now).returns(Time.parse('2009-07-01 00:00:00'))
    assert_equal '2009-07-02 00:00:00 ?future?', TimeFormatter.new(Time.parse('2009-07-02 00:00:00')).human
  end

  def test_formats_iso
    assert_equal '2009-07-01 12:30:00', TimeFormatter.new(Time.parse('2009-07-01 12:30:00')).iso
  end

  def test_formats_iso_date
    assert_equal '2009-07-01', TimeFormatter.new(Time.parse('2009-07-01 12:30:00')).iso_date
  end

  def test_formats_verbose
    assert_equal '1:30 PM on 01 July 2009',  TimeFormatter.new(Time.parse('2009-07-01 13:30:00')).verbose
    assert_equal '12:30 PM on 01 July 2009', TimeFormatter.new(Time.parse('2009-07-01 12:30:00')).verbose
  end

  def test_formats_rss
    time = Time.gm(2009, 7, 1, 12, 30, 0)
    assert_equal 'Wed, 01 Jul 2009 12:30:00 Z', TimeFormatter.new(time).rss
  end

  def test_formats_round_trip_local
    time = Time.parse('2009-07-01 12:30:00')
    assert_equal '2009-07-01T12:30:00.0000000-00:00', TimeFormatter.new(time).round_trip_local
  end

  def test_raises_with_message_for_unknown_format
    time = Time.parse('2009-07-01 12:30:00')
    assert_raise_with_message(RuntimeError, "Unknown time format :invalid_format") do
      TimeFormatter.new(time).invalid_format
    end
  end
end
