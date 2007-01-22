class Schedule
  def initialize(project, options = {})
    @project = project
    @poll_interval_sec = options[:poll_interval_sec] || 10
    @revisions = []
  end

  def run
    @project.build_if_necessary or sleep(@poll_interval_sec) while(true)
  end
end