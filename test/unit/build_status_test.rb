require File.dirname(__FILE__) + '/../test_helper'
require 'build_status'

class BuildStatusTest < Test::Unit::TestCase
  
  def setup
    @status = BuildStatus.new('')
  end
  
  def test_should_parse_elapsed_time     
    assert_equal 10, @status.match_elapsed_time('build_status.success.in10s')
    assert_equal 760, @status.match_elapsed_time('build_status.failed.in760s')    
  end
  
  def test_should_raise_exception_when_elapsed_time_not_parsable 
    assert_exception_when_parsing_elapsed_time('build_status.failed')
    assert_exception_when_parsing_elapsed_time('build_status.success')    
    assert_exception_when_parsing_elapsed_time('build_status.failed?s')              
  end
  
private
  def assert_exception_when_parsing_elapsed_time(file_name)
    assert_raises("Could not parse elapsed time.") do
      @status.match_elapsed_time(file_name)
    end  
  end  
end