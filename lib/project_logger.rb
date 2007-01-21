class ProjectLogger

  def initialize(project)
  end

  def build_started(build)
    Log.event("Build #{build.label} started")
  end
  
  def build_finished(build)
    message = "Build #{build.label} " + (build.successful? ? 'finished SUCCESSFULLY' : 'FAILED')
    Log.event(message)
  end
  
  def sleeping
    Log.event("Sleeping", :debug)
  end

  def polling_source_control
    Log.event("Polling source control", :debug)
  end
  
  def no_new_revisions_detected
    Log.event("No new revisions detected", :debug)
  end
  
  def new_revisions_detected(new_revisions)
    Log.event("New revision #{new_revisions.last.number} detected")
  end

end

Project.plugin :email_notifier