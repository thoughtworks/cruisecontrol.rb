class ProjectBlocker

  @@pid_files = {}

  def self.block(project)
    raise "Already holding a lock on project '#{project.name}'" if @@pid_files.include?(project.name)
    lock = File.open(pid_file(project), 'w')
    locked = lock.flock(File::LOCK_EX | File::LOCK_NB)
    if locked
      @@pid_files[project.name] = lock
    else
      lock.close
      raise "Another process (probably another builder) holds a lock on project '#{project.name}'.\n" + 
            "Look for a process with a lock on file #{pid_file(project)}"
    end
  end
  
  def self.block?(project)
    return false if @@pid_files.include?(project.name)    
    lock = File.open(pid_file(project), 'w')
    begin
      lock.flock(File::LOCK_EX | File::LOCK_NB)
    ensure
      lock.flock(File::LOCK_UN)
      lock.close
    end
  end
  
  def self.release(project)
    lock = @@pid_files[project.name]
    if lock
      lock.flock(File::LOCK_UN | File::LOCK_NB)
      lock.close
      File.delete(lock.path)
      @@pid_files.delete(project.name)
    end
  end
  
  def self.pid_file(project)
    File.expand_path(File.join(project.path, "builder.pid"))
  end

end
