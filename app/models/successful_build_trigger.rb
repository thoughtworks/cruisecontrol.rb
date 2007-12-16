class SuccessfulBuildTrigger
  attr_accessor :triggered_project
  attr_reader :last_successful_build

  def initialize(triggered_project, triggering_project_name)
    self.triggered_project = triggered_project
    self.triggering_project_name = triggering_project_name
    @last_successful_build = last_successful(@triggering_project.builds)
  end

  def revisions_to_build
    new_last_successful_build = last_successful(@triggering_project.builds)

    if new_last_successful_build.nil? ||
       @last_successful_build && (@last_successful_build.label == new_last_successful_build.label)
      []
    else
      @last_successful_build = new_last_successful_build           
      [@triggered_project.last_locally_known_revision]
    end
  end

  def ==(other)
    other.is_a?(SuccessfulBuildTrigger) &&
      triggered_project == other.triggered_project &&
      @triggering_project.name == other.triggering_project_name
  end

  def triggering_project_name
    @triggering_project.name
  end

  def triggering_project_name=(value)
    @triggering_project = Project.new(value.to_s)
  end

  private

  def last_successful(builds)
    builds.reverse.find(&:successful?)
  end
end
