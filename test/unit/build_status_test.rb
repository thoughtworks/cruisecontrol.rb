require File.dirname(__FILE__) + '/../test_helper'
require 'build_status'

class BuildStatusTest < Test::Unit::TestCase

  def test_should_parse_elapsed_time 
    status = BuildStatus.new('')   
    assert_equal '10', status.match_elapsed_time('build_status.success.in10s')
    assert_equal '760', status.match_elapsed_time('build_status.failed.in760s')
    assert_equal '', status.match_elapsed_time('build_status.failed.in760.12s')    
    assert_equal '', status.match_elapsed_time('build_status.failed')
    assert_equal '', status.match_elapsed_time('build_status.failed?s')    
  end   
end