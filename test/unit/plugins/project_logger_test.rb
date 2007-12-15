require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')

class ProjectLoggerTest < Test::Unit::TestCase  
  def setup
    @logger = ProjectLogger.new(nil)
    @mock_build = Object.new
  end

  def test_build_started
    @mock_build.expects(:label).returns(123)
    CruiseControl::Log.expects(:event).with("Build 123 started")

    @logger.build_started(@mock_build)
  end
  
  def test_build_finished_with_success
    @mock_build.expects(:label).returns(123)
    @mock_build.expects(:successful?).returns(true)
    CruiseControl::Log.expects(:event).with("Build 123 finished SUCCESSFULLY")

    @logger.build_finished(@mock_build)
  end  

  def test_build_finished_with_failure
    @mock_build.expects(:label).returns(123)
    @mock_build.expects(:successful?).returns(false)
    CruiseControl::Log.expects(:event).with("Build 123 FAILED")

    @logger.build_finished(@mock_build)
  end  
  
  def test_sleeping
    CruiseControl::Log.expects(:event).with("Sleeping", :debug)
    @logger.sleeping
  end

  def test_polling_source_control
    CruiseControl::Log.expects(:event).with("Polling source control", :debug)
    @logger.polling_source_control
  end
  
  def test_no_new_revisions_detected
    CruiseControl::Log.expects(:event).with("No new revisions detected", :debug)
    @logger.no_new_revisions_detected
  end

  def test_new_revisions_detected
    @mock_revision = Object.new
    @mock_revision.expects(:number).returns(9)
    CruiseControl::Log.expects(:event).with("New revision 9 detected")

    @logger.new_revisions_detected([@mock_revision])
  end
  
  def test_build_loop_failed
    @mock_error = Object.new
    @mock_error.expects(:message).returns("Blown up")
    @mock_error.expects(:backtrace).returns(["here:10"])
    
    CruiseControl::Log.expects(:event).with("Build loop failed", :debug)
    CruiseControl::Log.expects(:debug).with("Object: Blown up\n  here:10")

    @logger.build_loop_failed(@mock_error)
  end

end