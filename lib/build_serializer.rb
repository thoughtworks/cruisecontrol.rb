class BuildSerializer
  include ActionView::Helpers::DateHelper
  
  def self.serialize(project, &block)
    BuildSerializer.new(project).serialize(&block)
  end
  
  def initialize(project)
    @project = project
  end
  
  def serialize
    @start_time = Time.now
    lock = FileLock.new(CRUISE_DATA_ROOT + "/projects/build_serialization.lock")
    begin
      lock.lock
    rescue FileLock::LockUnavailableError
      unless @already_told
        @project.notify(:queued) 
        @already_told = true
      end
      wait
      timeout or retry
    end

    yield
  ensure
    lock.release
  end
  
  def timeout
    if Time.now - @start_time >= Configuration.serialized_build_timeout
      @project.notify(:timed_out)
      raise "Timed out after waiting to build for #{distance_of_time_in_words(@start_time, Time.now)}"
    end
  end
  
  def wait
    sleep 5
  end
end