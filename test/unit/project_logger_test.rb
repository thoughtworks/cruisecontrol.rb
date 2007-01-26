require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'project_logger'

class ProjectLoggerTest < Test::Unit::TestCase
  
  def setup
    @logger = ProjectLogger.new(nil)
    @mock_build = Object.new
  end

  def test_build_started
    @mock_build.expects(:label).returns(123)
    Log.expects(:event).with("Build 123 started")

    @logger.build_started(@mock_build)

    Log.verify
  end
  
  def test_build_finished_with_success
    @mock_build.expects(:label).returns(123)
    @mock_build.expects(:successful?).returns(true)
    Log.expects(:event).with("Build 123 finished SUCCESSFULLY")

    @logger.build_finished(@mock_build)

    Log.verify
  end  

  def test_build_finished_with_failure
    @mock_build.expects(:label).returns(123)
    @mock_build.expects(:successful?).returns(false)
    Log.expects(:event).with("Build 123 FAILED")

    @logger.build_finished(@mock_build)

    Log.verify
  end  
  
  def test_sleeping
    Log.expects(:event).with("Sleeping", :debug)
    @logger.sleeping
    Log.verify
  end

  def test_polling_source_control
    Log.expects(:event).with("Polling source control", :debug)
    @logger.polling_source_control
    Log.verify
  end
  
  def test_no_new_revisions_detected
    Log.expects(:event).with("No new revisions detected", :debug)
    @logger.no_new_revisions_detected
    Log.verify
  end

  def test_new_revisions_detected
    @mock_revision = Object.new
    @mock_revision.expects(:number).returns(9)
    Log.expects(:event).with("New revision 9 detected")

    @logger.new_revisions_detected([@mock_revision])

    Log.verify
  end
  
  def test_build_loop_failed
    @mock_error = Object.new
    @mock_error.expects(:message).returns("Blown up")
    @mock_error.expects(:backtrace).returns(["here:10"])
    
    Log.expects(:event).with("Build loop failed", :debug)
    Log.expects(:debug).with("Object: Blown up\n  here:10")

    @logger.build_loop_failed(@mock_error)

    Log.verify
  end

end