class FileLock
  class LockUnavailableError < RuntimeError; end
  class AlreadyLockedError < RuntimeError; end

  @@lock_files = {}
  
  def initialize(lock_file_name, locked_object_description = lock_file_name)
    @lock_file_name, @locked_object_description = lock_file_name, locked_object_description
  end
  
  def lock
    if @@lock_files.include?(@lock_file_name)
      raise AlreadyLockedError, "Already holding a lock on #@locked_object_description"
      
    end
    
    lock_file = File.open(@lock_file_name, 'w')
    locked = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
    if locked
      @@lock_files[@lock_file_name] = lock_file
    else
      lock_file.close
      raise LockUnavailableError, 
            "Another process holds a lock on #@locked_object_description.\n" + 
            "Look for a process with a lock on file #@lock_file_name"
    end
  end
  
  def locked?
    return true if @@lock_files.include?(@lock_file_name)

    lock_file = File.open(@lock_file_name, 'w')
    begin
      return !lock_file.flock(File::LOCK_EX | File::LOCK_NB)
    ensure
      lock_file.flock(File::LOCK_UN | File::LOCK_NB)
      lock_file.close
    end
  end
  
  def release
    lock_file = @@lock_files[@lock_file_name]
    if lock_file
      lock_file.flock(File::LOCK_UN | File::LOCK_NB)
      lock_file.close
      File.delete(lock_file.path)
      @@lock_files.delete(@lock_file_name)
    end
  end
end
