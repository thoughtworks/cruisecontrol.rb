require File.dirname(__FILE__) + '/../test_helper'
require 'build_status'

class BuildStatusTest < Test::Unit::TestCase

  def test_should_parse_elapsed_time 
    status = BuildStatus.new('')   
    assert_equal '9.359', status.match_elapsed_time('build_status.success.in9.359s')
    assert_equal '75.123', status.match_elapsed_time('build_status.failed.in75.123s')
    assert_equal '', status.match_elapsed_time('build_status.failed')
  end   
end