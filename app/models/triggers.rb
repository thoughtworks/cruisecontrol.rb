class ChangeInSourceControlTrigger
  def initialize(triggered_project)
    @triggered_project = triggered_project 
  end

  def revisions_to_build
    @triggered_project.notify :polling_source_control
    @triggered_project.new_revisions
  end
end

class SuccessfulBuildTrigger
  attr_accessor :triggering_project_name, :triggered_project
  
  def initialize(triggered_project, triggering_project_name)
    @triggered_project = triggered_project
    @triggering_project_name = triggering_project_name.to_s
  end
  
  def revisions_to_build
    triggering_project = Project.new(@triggering_project_name)
    last_successful_build = last_successful(triggering_project.builds)
    
    if last_successful_build.nil? || @triggered_project.find_build(last_successful_build.label)
      []
    else
      [Revision.new(last_successful_build.label.to_i)]
    end
  end
  
  def ==(other)
    other.is_a?(SuccessfulBuildTrigger) &&
      triggered_project == other.triggered_project &&
      triggering_project_name == other.triggering_project_name
  end
  
  private
  
  def last_successful(builds)
    builds.reverse.find(&:successful?)
  end
end

