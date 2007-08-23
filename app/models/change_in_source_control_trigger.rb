class ChangeInSourceControlTrigger
  def initialize(triggered_project)
    @triggered_project = triggered_project
  end

  def revisions_to_build
    @triggered_project.notify :polling_source_control
    @triggered_project.new_revisions
  end
end
