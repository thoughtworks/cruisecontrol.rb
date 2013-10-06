#
# this plugin logs build events to a project log file in $CRUISE/<project name>_builder.log
#
# (this plugin is built in and needs no customization)
#
class ProjectLogger < BuilderPlugin
  def build_started(build)
    CruiseControl::Log.event("Build #{build.label} started")
  end
  
  def build_finished(build)
    message = "Build #{build.label} " + (build.successful? ? 'finished SUCCESSFULLY' : 'FAILED')
    CruiseControl::Log.event(message)
  end
  
  def sleeping
    CruiseControl::Log.event("Sleeping", :debug)
  end

  def polling_source_control
    CruiseControl::Log.event("Polling source control", :debug)
  end
  
  def no_new_revisions_detected
    CruiseControl::Log.event("No new revisions detected", :debug)
  end
  
  def new_revisions_detected(new_revisions)
    if new_revisions.last.nil?
      CruiseControl::Log.event("Changes detected")
    else
      CruiseControl::Log.event("New revision #{new_revisions.last.number} detected")
    end
  end

  def build_loop_failed(error)
    CruiseControl::Log.event("Build loop failed", :debug)
    backtrace = error.backtrace.map { |line| "  #{line}" }.join("\n") rescue ""
    CruiseControl::Log.debug("#{error.class}: #{error.message}\n#{backtrace}")
  end
end

Project.plugin :project_logger