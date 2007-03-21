require File.dirname(__FILE__) + '/test_helper'

class GrowlNotifierTest < Test::Unit::TestCase

  def setup
    @notifier = GrowlNotifier.new
    # stub the logging
    logger = stub('logger', :debug => nil)
    @notifier.stubs(:logger).returns(logger)
  end

  def test_should_have_accessor_for_subscribers
    subscribers = %w[192.168.0.1 192.168.0.2]
    @notifier.subscribers = subscribers
    assert_equal subscribers, @notifier.subscribers
  end

  def test_should_provide_growl_clients_from_subscribers
    @notifier.subscribers = %w[192.168.0.1 192.168.0.2]
    expected = ["first growl client", "second growl client"]
    Growl.expects(:new).times(2).returns(*expected)
    assert_equal expected, @notifier.growl_clients
  end
  
  def test_should_notify_clients_on_broken_build
    assert_growl_clients_notified(GrowlNotifier::BUILD_BROKEN_NOTIFICATION, "TestProject Build 314 - BROKEN") do
      mock_project = mock('project', :name => 'TestProject')
      mock_build   = mock('build', :project => mock_project, :label => "314")
      @notifier.build_broken(mock_build, :previous_build)  
    end
  end
  
  def test_should_notify_clients_on_fixed_build
    assert_growl_clients_notified(GrowlNotifier::BUILD_FIXED_NOTIFICATION, "TestProject Build 314 - FIXED") do
      mock_project = mock('project', :name => 'TestProject')
      mock_build   = mock('build', :project => mock_project, :label => "314")
      @notifier.build_fixed(mock_build, :previous_build)  
    end
  end
  
  def assert_growl_clients_notified(expected_notification, expected_message)
    mock_client = mock('growl_client')
    mock_client.expects(:notify).with(expected_notification, GrowlNotifier::APPLICATION_NAME, expected_message)
    @notifier.expects(:growl_clients).returns([mock_client])
    yield if block_given?
  end
  
end
