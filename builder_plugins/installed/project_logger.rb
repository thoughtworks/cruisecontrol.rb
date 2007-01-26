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

  def build_loop_failed(error)
    Log.event("Build loop failed", :debug)
    Log.debug("#{error.class}: #{error.message}\n" + error.backtrace.map { |line| "  #{line}" }.join("\n"))
  end

end

Project.plugin :project_logger