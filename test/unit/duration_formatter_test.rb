require 'test_helper'

class DurationFormatterTest < ActiveSupport::TestCase
  def test_format_general
    assert_equal '0 seconds',         DurationFormatter.new(0).general
    assert_equal '1 second',          DurationFormatter.new(1).general
    assert_equal '25 seconds',        DurationFormatter.new(25).general
    assert_equal '1 minute',          DurationFormatter.new(60).general
    assert_equal '1 minute',          DurationFormatter.new(61).general
    assert_equal '33 minutes',        DurationFormatter.new(2005).general
    assert_equal '1 hour',            DurationFormatter.new(3600).general
    assert_equal '1 hour',            DurationFormatter.new(3601).general
    assert_equal '1 hour 1 minute',   DurationFormatter.new(3661).general
    assert_equal '2 hours 5 minutes', DurationFormatter.new(7500).general
    assert_equal '2 hours 5 minutes', DurationFormatter.new(7501).general
  end

  def test_format_precise
    assert_equal '0 seconds',                          DurationFormatter.new(0).precise
    assert_equal '1 second',                           DurationFormatter.new(1).precise
    assert_equal '25 seconds',                         DurationFormatter.new(25).precise
    assert_equal '1 minute',                           DurationFormatter.new(60).precise
    assert_equal '1 minute and 1 second',              DurationFormatter.new(61).precise
    assert_equal '33 minutes and 25 seconds',          DurationFormatter.new(2005).precise
    assert_equal '1 hour',                             DurationFormatter.new(3600).precise
    assert_equal '1 hour and 1 second',                DurationFormatter.new(3601).precise
    assert_equal '1 hour and 1 minute and 1 second',   DurationFormatter.new(3661).precise
    assert_equal '2 hours and 5 minutes',              DurationFormatter.new(7500).precise
    assert_equal '2 hours and 5 minutes and 1 second', DurationFormatter.new(7501).precise
  end

  def test_raises_with_message_for_unknown_format
    assert_raise_with_message(RuntimeError, "Unknown duration format :invalid_format") do
      DurationFormatter.new(0).invalid_format
    end
  end
end
