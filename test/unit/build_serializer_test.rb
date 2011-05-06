require 'test_helper'

class BuildSerializerTest < ActiveSupport::TestCase
  def setup
    @project = Object.new
    @serializer = BuildSerializer.new(@project)
  end
  
  def test_serialize_when_lock_is_available
    lock = AvailableLock.new
    FileLock.expects(:new).
             with(Configuration.projects_root.join("build_serialization.lock")).
             returns(lock)
    
    block_yielded = false
    
    @serializer.serialize do
      assert lock.locked?
      block_yielded = true
    end
    
    assert_false lock.locked?
    assert block_yielded
  end
  
  def test_serialize_handles_exceptions_in_block_passed_to_it
    lock = AvailableLock.new
    FileLock.expects(:new).returns(lock)

    assert_raise_with_message(RuntimeError, "some exception") do
      @serializer.serialize { raise "some exception" }
    end
    
    assert_false lock.locked?
  end
  
  def test_serialize_when_lock_is_not_available_for_first_10_tries
    lock = AvailableLock.new
    def lock.lock
      @tries += 1
      raise FileLock::LockUnavailableError, "not obtained" unless @tries > 10
      @locked = true
    end

    FileLock.expects(:new).returns(lock)
    
    @project.expects(:notify).with(:queued).once
    @serializer.stubs(:wait)
    @serializer.serialize do
      assert lock.locked?
    end
    
    assert_equal 11, lock.tries
    assert_false lock.locked?
  end
    
  def test_serialize_when_times_out
    Configuration.stubs(:serialized_build_timeout).returns(5.hours)
    lock = AvailableLock.new
    Time.stubs(:now).returns(Time.at(0))
    def @serializer.wait
      now = Time.now + 5.minutes
      Time.stubs(:now).returns(now)
    end
    lock.stubs(:lock).raises(FileLock::LockUnavailableError, "not obtained")
    
    @project.expects(:notify).with(:queued).once
    @project.expects(:notify).with(:timed_out).once
    FileLock.expects(:new).returns(lock)
    assert_raise_with_message(RuntimeError, "Timed out after waiting to build for about 5 hours") do
      @serializer.serialize do
        fail "should never run"
      end
    end
    
    assert_equal Time.at(5.hours.to_i), Time.now
    assert_false lock.locked?
  end
  
  class AvailableLock
    attr_accessor :tries
    
    def initialize
      @tries = 0
      @locked = false
    end
    
    def lock
      @tries += 1
      @locked = true
    end
    
    def release
      @locked = false
    end
    
    def locked?
      @locked
    end
  end
end