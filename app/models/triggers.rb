class ChangeInSourceControlTrigger
  def get_revisions_to_build(project)
    project.notify :polling_source_control      
    project.new_revisions
  end
end

class SuccessfulBuildTrigger
  attr_accessor :triggering_project_name
  
  def initialize(triggering_project_name)
    @triggering_project_name = triggering_project_name
  end
  
  def get_revisions_to_build(project)
    triggering_project = Project.new(@triggering_project_name)
    last_successful_build = last_successful(triggering_project.builds)
    
    if !last_successful_build || project.find_build(last_successful_build.label)
      []
    else
      [Revision.new(last_successful_build.label)]
    end
  end
  
  def ==(other)
    other.is_a?(SuccessfulBuildTrigger) && triggering_project_name == other.triggering_project_name
  end
  
  private
  
  def last_successful(builds)
    builds.reverse.each do |build|
      return build if build.successful?
    end
    return nil
  end
end

class SvnExternalTrigger < ChangeInSourceControlTrigger
  def get_revisions_to_build
    if svn_external_changed
      super
    end
  end
end

# this is probably a hack, how better to do this?
class Object
  def successful_build_of(project_name)
    SuccessfulBuildTrigger.new(project_name.to_s)
  end
  
  def change_in_source_control
    ChangeInSourceControlTrigger.new
  end
end

class Project
  def triggered_by(trigger)
    trigger = SuccessfulBuildTrigger.new(trigger) if trigger.is_a?(String) || trigger.is_a?(Symbol)
    @trigger = trigger
  end
end

