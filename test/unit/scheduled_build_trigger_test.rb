require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ScheduledBuildTriggerTest < Test::Unit::TestCase
  include FileSandbox
  include BuildFactory

  def setup
    setup_sandbox    
  end
  
  def teardown
    teardown_sandbox
  end
  
  def test_build_should_be_necessary_if_build_triggered
    project = mock(:build_requested? => true)
    assert ScheduledBuildTrigger.new(project).build_necessary?([])
  end
  
  def test_build_should_be_necessary_if_time_exceeds_next_build_time
    default_project = stub("Project", :build_requested? => false)
    
    assert !(ScheduledBuildTrigger.new(default_project, :start_time => 1.minute.from_now).build_necessary?([]))
    assert ScheduledBuildTrigger.new(default_project, :start_time => 1.minute.ago).build_necessary?([])
    
    trigger = ScheduledBuildTrigger.new(default_project, :start_time => 1.minute.from_now)
    future = 2.minutes.from_now
    Time.stubs(:now).returns(future)
    assert trigger.build_necessary?([])
  end
  
  def test_build_should_be_necessary_if_time_exceeds_build_interval
    default_project = stub("Project", :build_requested? => false)
    
    trigger = ScheduledBuildTrigger.new(default_project, :build_interval => 1.minute)
    future = 2.minutes.from_now
    Time.stubs(:now).returns(future)
    assert trigger.build_necessary?([])    
  end
  
  def test_build_necessary_should_handle_the_passage_of_time
    default_project = stub("Project", :build_requested? => false)

    should_build = 2.minutes.from_now
    should_not_build = 3.minutes.from_now
    should_build_again = 5.minutes.from_now

    trigger = ScheduledBuildTrigger.new(default_project, :start_time => 1.minute.from_now, :build_interval => 3.minutes)

    assert !trigger.build_necessary?([])
    
    Time.stubs(:now).returns should_build
    assert trigger.build_necessary?([])
    
    Time.stubs(:now).returns should_not_build
    assert !trigger.build_necessary?([])
    
    Time.stubs(:now).returns should_build_again
    assert trigger.build_necessary?([])
  end
end