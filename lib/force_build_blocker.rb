class ForceBuildBlocker < ProjectBlocker
  
  def self.pid_file_name
    'force_build_blocker.pid'
  end
  
  def self.cannot_lock_error_message(project)
    "Another force build has started on project '#{project.name}'.\n" + 
    "Look for a process with a lock on file #{pid_file(project)}"    
  end
  
  def self.already_lock_error_message(project)
    "Another force build is running on project '#{project.name}'"   
  end
end