class BuildBlocker < ProjectBlocker

  def self.pid_file_name
    'build_in_progress.pid'
  end
  
  def self.cannot_lock_error_message(project)
    "Another build has started on project '#{project.name}'.\n" + 
    "Look for a process with a lock on file #{pid_file(project)}"    
  end
  
  def self.already_lock_error_message(project)
    "Another build is running on project '#{project.name}'"   
  end
end