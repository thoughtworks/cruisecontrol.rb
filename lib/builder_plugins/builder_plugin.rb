# BuilderPlugin is the superclass of all CC.rb plugins. It does not provide any functionality
# except a basic initializer that accepts as an argument the current project.
# 
# CC.rb plugins offer a rich notification system for tracking every aspect of the build lifecycle. In rough order,
# they are:
#
# * polling_source_control
# * no_new_revisions_detected OR new_revisions_detected(revisions)
# * build_requested
# * queued
# * timed_out
# * build_initiated
# * configuration_modified
# * build_started
# * build_finished
# * build_broken OR build_fixed
# * build_loop_failed
# * sleeping
class BuilderPlugin
  attr_reader :project
  
  def initialize(project)
    @project = project
  end
  
  class << self
    def known_event?(event_name)
      self.instance_methods(false).include? event_name.to_s
    end
  end
  
  # Called by ChangeInSourceControlTrigger to indicate that it is about to poll source control.
  def polling_source_control
  end
  
  # Called by ChangeInSourceControlTrigger to indicate that no new revisions have been detected.
  def no_new_revisions_detected
  end
  
  # Called by ChangeInSourceControlTrigger to indicate that new revisions were detected.
  def new_revisions_detected(revisions)
  end
  
  # Called by Project to indicate that a build has explicitly been requested by the user.
  def build_requested
  end  
  
  # Called by BuildSerializer if it another build is still running and it cannot acquire the build serialization lock.
  # It will retry until it times out. Occurs only if build serialization is enabled in your CC.rb configuration.
  def queued
  end
  
  # Called by BuildSerializer if it times out attempting to acquire the build serialization lock due to another build
  # still running. Occurs only if build serialization is enabled in your CC.rb configuration.
  def timed_out
  end
  
  # Called by Project at the start of a new build before any other build events.
  def build_initiated
  end
  
  # Called by Project at the start of a new build to indicate that the configuration has been modified,
  # after which the build is aborted.
  def configuration_modified
  end

  # Called by Project after some basic logging and the configuration_modified check and just before the build begins running, 
  def build_started(build)
  end
  
  # Called by Project immediately after the build has finished running.
  def build_finished(build)
  end
  
  # Called by Project after the completion of a build if the previous build was successful and this one is a failure.
  def build_broken(build, previous_build)
  end
  
  # Called by Project after the completion of a build if the previous build was a failure and this one was successful.
  def build_fixed(build, previous_build)
  end
  
  # Called by Project if the build fails internally with a CC.rb exception.
  def build_loop_failed(exception)
  end
  
  # Called by Project at the end of a build to indicate that the build loop is once again sleeping.
  def sleeping
  end
  
end