# this plugin prints major events like builds starting / passing / failing to console
#
# it is useful in debugging
#
# (this plugin is built in and needs no customization)
#
class MinimalConsoleLogger
  def initialize(project)
  end

  def build_started(build)
    puts "Build #{build.label} started"
  end
  
  def build_finished(build)
    puts "Build #{build.label} " + (build.successful? ? 'finished SUCCESSFULLY' : 'FAILED')
  end
  
  def new_revisions_detected(new_revisions)
    puts "New revision #{new_revisions.last.number} detected"
  end

  def build_loop_failed(error)
    puts "Build loop failed"
    puts "#{error.class}: #{error.message}\n" + error.backtrace.map { |line| "  #{line}" }.join("\n")
  end
  
  def configuration_modified
    puts "Configuration modification detected"
  end
end

Project.plugin :minimal_console_logger