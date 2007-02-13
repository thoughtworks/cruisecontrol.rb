require File.dirname(__FILE__) + '/../test_helper'

class BuildStatusTest < Test::Unit::TestCase

  def test_never_built_is_true_when_file_is_missing
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns([])
    assert_equal true, BuildStatus.new("artifacts_directory").never_built?
  end
  
  def test_never_built_is_false_when_file_exists
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns(['build_status.anything'])
    assert_equal false, BuildStatus.new("artifacts_directory").never_built?
  end

  def test_succeeded_is_true_when_file_is___success__
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns(['build_status.success'])
    assert_equal true, BuildStatus.new("artifacts_directory").succeeded?
  end

  def test_succeeded_is_false_when_file_is_not___success__
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns([])
    assert_equal false, BuildStatus.new("artifacts_directory").succeeded?
  end
  
  def test_succeed_creates_file___success
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status.foo'])
    FileUtils.expects(:rm_f).with(["artifacts_directory/build_status.foo"])
    FileUtils.expects(:touch).with("artifacts_directory/build_status.success.in3.5s")
    BuildStatus.new("artifacts_directory").succeed!(3.5)
  end
  
  def test_failed_is_true_when_file_is___failed__
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns(['build_status.failed.in3.5s'])
    assert_equal true, BuildStatus.new("artifacts_directory").failed?
  end

  def test_failed_is_false_when_file_is_not___failed__
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns([])
    assert_equal false, BuildStatus.new("artifacts_directory").failed?
  end
  
  def test_fail_creates_file___failed__
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status.foo'])
    FileUtils.expects(:rm_f).with(["artifacts_directory/build_status.foo"])
    FileUtils.expects(:touch).with("artifacts_directory/build_status.failed.in3.5s")
    BuildStatus.new("artifacts_directory").fail!(3.5)   
  end
    
  def test_created_at_returns_creation_time_for_status_file
    now = Time.now
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns([:some_file])
    File.expects(:mtime).with(:some_file).returns(now)
    assert_equal now, BuildStatus.new("artifacts_directory").created_at
  end
  
  def test_created_at_returns_nil_when_file_not_exist
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns([])
    assert_equal nil, BuildStatus.new("artifacts_directory").created_at    
  end
  
  def test_to_s_returns_status_file_name_without_underscores
    assert_equal 'never_built', BuildStatus.new("artifacts_directory").to_s
  end
  
  def test_elapsed_time_should_return_elapsed_seconds_if_build_sccessed
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns(['build_status.success.in3.52s'])
    assert_equal '3.52', BuildStatus.new("artifacts_directory").elapsed_time
  end
  
  def test_elapsed_time_should_return_blank_if_elapsed_time_not_availabe
    Dir.expects(:'[]').with("artifacts_directory/build_status.*").returns(['build_status.hoo'])
    assert_equal '', BuildStatus.new("artifacts_directory").elapsed_time    
  end
  
end