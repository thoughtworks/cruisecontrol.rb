require File.dirname(__FILE__) + '/../test_helper'
require 'build_status'

class BuildStatusTest < Test::Unit::TestCase
  
  def setup
    @status = BuildStatus.new('')
  end
  
  def test_should_parse_elapsed_time     
    assert_equal 10, @status.match_elapsed_time('build-1-success.in10s')
    assert_equal 760, @status.match_elapsed_time('build-2-failed.in760s')    
  end
  
  def test_should_raise_exception_when_elapsed_time_not_parsable 
    assert_exception_when_parsing_elapsed_time('build_status.failed')
    assert_exception_when_parsing_elapsed_time('build_status.success')    
    assert_exception_when_parsing_elapsed_time('build_status.failed?s')              
  end

  def test_never_built_is_true_when_file_is_missing
    assert_equal true, BuildStatus.new("artifacts_directory").never_built?
  end

  def test_never_built_is_false_when_file_exists
    File.expects(:"exist?").with("artifacts_directory").returns(true)
    assert_equal false, BuildStatus.new("artifacts_directory").never_built?
  end

  def test_succeeded_is_true_when_file_is___success__
    File.expects(:"exist?").with("build-1-success").returns(true)
    assert_equal true, BuildStatus.new("build-1-success").succeeded?
  end

  def test_succeeded_is_false_when_file_is_not___success__
    assert_equal false, BuildStatus.new("artifacts_directory").succeeded?
  end

  def test_succeed_creates_file___success
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status.foo'])
    FileUtils.expects(:mv).with("artifacts_directory", "artifacts_directory-success.in3.5s")
    BuildStatus.new("artifacts_directory").succeed!(3.5)
  end

  def test_failed_is_true_when_file_is___failed__
    File.expects(:"exist?").with('build-1-failed').returns(true)
    assert_equal true, BuildStatus.new("build-1-failed").failed?
  end

  def test_failed_is_false_when_file_is_not___failed__
    assert_equal false, BuildStatus.new("artifacts_directory").failed?
  end

  def test_fail_creates_file___failed__
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status.foo'])
    FileUtils.expects(:mv).with("artifacts_directory", "artifacts_directory-failed.in3.5s")
    BuildStatus.new("artifacts_directory").fail!(3.5)
  end

  def test_created_at_returns_creation_time_for_status_file
    now = Time.now
    File.expects(:mtime).with('artifacts_directory').returns(now)
    assert_equal now, BuildStatus.new("artifacts_directory").created_at
  end

  def test_timestamp_returns_later_mtime_of_build_log_or_build_dir
    build_log_mtime = Time.now
    File.expects(:mtime).with("artifacts_directory/build.log").returns(build_log_mtime)

    build_dir_mtime = 2.days.since
    File.expects(:mtime).with("artifacts_directory").returns(build_dir_mtime)    

    assert_equal build_dir_mtime, BuildStatus.new("artifacts_directory").timestamp
  end
  
  def test_timestamp_returns_build_dir_mtime_if_build_log_not_exist
    build_dir_mtime = Time.now
    File.expects(:mtime).with("artifacts_directory").returns(build_dir_mtime)
    File.expects(:mtime).with("artifacts_directory/build.log").raises
    assert_equal build_dir_mtime, BuildStatus.new("artifacts_directory").timestamp
  end

  def test_created_at_returns_nil_when_file_not_exist
    assert_equal nil, BuildStatus.new("artifacts_directory").created_at
  end

  def test_to_s_returns_status_file_name_without_underscores
    assert_equal 'never_built', BuildStatus.new("artifacts_directory").to_s
  end

  def test_elapsed_time_should_return_elapsed_seconds_if_build_succeeded
    assert_equal 3, BuildStatus.new("build-1-success.in3s").elapsed_time
  end

  def test_elapsed_time_should_return_blank_if_elapsed_time_not_availabe
    assert_raises("Could not parse elapsed time.") do
      BuildStatus.new("artifacts_directory").elapsed_time
    end
  end

  def test_elapsed_time_in_progress
    File.expects(:"exist?").with('build-1-incomplete').returns(true)
    File.expects(:mtime).with('build-1-incomplete').returns(Time.local(2000,"jan",1,20,15, 1))
    Time.expects(:now).returns(Time.local(2000,"jan",1,20,15,10))
    assert_equal 9, BuildStatus.new("build-1-incomplete").elapsed_time_in_progress
  end

  def test_elapsed_time_in_progress_should_return_nil_when_not_incomplete
    assert_nil BuildStatus.new("build-1-success.in123s").elapsed_time_in_progress
  end

  def test_elapsed_time_in_progress_ceils_fractionals
    File.expects(:"exist?").with('build-1-incomplete').returns(true)
    File.expects(:mtime).with('build-1-incomplete').returns(Time.local(2000,"jan",1,20,15, 1))
    time_with_fractional_seconds = Time.local(2000,"jan",1,20,15,10) + 0.2 #difference is 9.2 seconds
    Time.expects(:now).returns(time_with_fractional_seconds)
    assert_equal 10, BuildStatus.new("build-1-incomplete").elapsed_time_in_progress
  end
  
  private

  def assert_exception_when_parsing_elapsed_time(file_name)
    assert_raises("Could not parse elapsed time.") do
      @status.match_elapsed_time(file_name)
    end  
  end  
end