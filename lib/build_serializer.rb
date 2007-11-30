class BuildSerializer
  include ActionView::Helpers::DateHelper
  
  def self.serialize(&block)
    BuildSerializer.new.serialize(&block)
  end
  
  def serialize
    @start_time = Time.now
    lock = FileLock.new(Configuration.projects_directory + "/build_serialization.lock")
    begin
      lock.lock
    rescue FileLock::LockUnavailableError
      wait
      timeout or retry
    end

    yield
  ensure
    lock.release
  end
  
  def timeout
    if Time.now - @start_time >= Configuration.serialized_build_timeout
      raise "Timed out after waiting to build for #{distance_of_time_in_words(@start_time, Time.now)}"
    end
  end
  
  def wait
    sleep 5
  end
end