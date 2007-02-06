class ProjectBlocker

  @@pid_files = {}
  
  def self.block(project)
    raise already_locked_error_message(project) if @@pid_files.include?(pid_file(project))
    lock = File.open(pid_file(project), 'w')
    locked = lock.flock(File::LOCK_EX | File::LOCK_NB)
    if locked
      @@pid_files[pid_file(project)] = lock
    else
      lock.close
      raise cannot_lock_error_message(project)
    end
  end
  
  def self.blocked?(project)
    return true if @@pid_files.include?(pid_file(project))

    lock = File.open(pid_file(project), 'w')
    begin
      return !lock.flock(File::LOCK_EX | File::LOCK_NB)
    ensure
      lock.flock(File::LOCK_UN | File::LOCK_NB)
      lock.close
    end
  end
  
  def self.release(project)
    lock = @@pid_files[pid_file(project)]
    if lock
      lock.flock(File::LOCK_UN | File::LOCK_NB)
      lock.close
      File.delete(lock.path)
      @@pid_files.delete(pid_file(project))
    end
  end
  
  def self.pid_file(project)
    File.expand_path(File.join(project.path, pid_file_name))
  end

  def self.cannot_lock_error_message(project)
    "Another process (probably another builder) holds a lock on project '#{project.name}'.\n" + 
            "Look for a process with a lock on file #{pid_file(project)}"
  end
  
  def self.already_locked_error_message(project)
    "Already holding a lock on project '#{project.name}'"
  end
  
  def self.pid_file_name
    "builder.pid"
  end
end
