# SuccessfulBuildTrigger is one of two build triggers included in CC.rb by default (see also:
# ChangeInSourceControlTrigger). It allows you to configure a build that is dependent on the 
# success of another build--in effect, build chaining.
class SuccessfulBuildTrigger
  attr_accessor :triggered_project
  attr_reader :last_successful_build

  def initialize(triggered_project, triggering_project_name)
    self.triggered_project = triggered_project
    self.triggering_project_name = triggering_project_name
  end

  def build_necessary?(reasons)
    new_last_successful_build = last_successful(@triggering_project.builds)

    if new_last_successful_build.nil? || still_the_same_build?(new_last_successful_build)
      false
    else
      @last_successful_build = new_last_successful_build
      reasons << "Triggered by project #{triggering_project_name}'s build #{@last_successful_build.label}"
      true
    end
  end

  def last_successful_build
    @last_successful_build ||= (last_successful(@triggering_project.builds) || :none)
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
    @triggering_project = Project.find(value.to_s)
  end

  private

  def still_the_same_build?(new_build)
    @last_successful_build &&
        @last_successful_build != :none &&
        @last_successful_build.label == new_build.label
  end

  def last_successful(builds)
    builds.reverse.find(&:successful?)
  end
end
