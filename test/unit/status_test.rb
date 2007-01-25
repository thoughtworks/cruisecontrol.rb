require File.dirname(__FILE__) + '/../test_helper'

class StatusTest < Test::Unit::TestCase

  def test_never_built_is_true_when_file_is_missing
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns([])
    assert_equal true, Status.new("artifacts_directory").never_built?
  end
  
  def test_never_built_is_false_when_file_exists
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns(['build_status = anything'])
    assert_equal false, Status.new("artifacts_directory").never_built?
  end

  def test_succeeded_is_true_when_file_is___success__
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns(['build_status = success'])
    assert_equal true, Status.new("artifacts_directory").succeeded?
  end

  def test_succeeded_is_false_when_file_is_not___success__
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns([])
    assert_equal false, Status.new("artifacts_directory").succeeded?
  end
  
  def test_succeed_creates_file___success__
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status = foo'])
    FileUtils.expects(:rm_f).with(["artifacts_directory/build_status = foo"])
    FileUtils.expects(:touch).with("artifacts_directory/build_status = success")
    Status.new("artifacts_directory").succeed!
  end
  
  def test_failed_is_true_when_file_is___failed__
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns(['build_status = failed'])
    assert_equal true, Status.new("artifacts_directory").failed?
  end

  def test_failed_is_false_when_file_is_not___failed__
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns([])
    assert_equal false, Status.new("artifacts_directory").failed?
  end
  
  def test_fail_creates_file___failed__
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status = foo'])
    FileUtils.expects(:rm_f).with(["artifacts_directory/build_status = foo"])
    FileUtils.expects(:touch).with("artifacts_directory/build_status = failed")
    Status.new("artifacts_directory").fail!    
  end
  
  def test_build_creates_file___building__
    Dir.stubs(:'[]').returns(['artifacts_directory/build_status = foo'])
    FileUtils.expects(:rm_f).with(["artifacts_directory/build_status = foo"])
    FileUtils.expects(:touch).with("artifacts_directory/build_status = building")
    Status.new("artifacts_directory").building!
  end
  
  def test_created_at_returns_creation_time_for_status_file
    now = Time.now
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns([:some_file])
    File.expects(:mtime).with(:some_file).returns(now)
    assert_equal now, Status.new("artifacts_directory").created_at
  end
  
  def test_created_at_returns_nil_when_file_not_exist
    Dir.expects(:'[]').with("artifacts_directory/build_status = *").returns([])
    assert_equal nil, Status.new("artifacts_directory").created_at    
  end
  
  def test_to_s_returns_status_file_name_without_underscores
    assert_equal 'never_built', Status.new("artifacts_directory").to_s
  end
  
end