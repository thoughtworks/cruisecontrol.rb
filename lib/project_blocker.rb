class ProjectBlocker
  def self.block(project)
    lock_for(project).lock
  end
  
  def self.blocked?(project)
    lock_for(project).locked?
  end
  
  def self.release(project)
    lock_for(project).release
  end
  
  private
  
  def self.lock_for(project)
    lock_file = File.expand_path(File.join(project.path, "builder.lock"))
    FileLock.new(lock_file, "project '#{project.name}'")
  end
end
