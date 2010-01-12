class ScheduledBuildTrigger
  attr_accessor :build_interval
  
  def initialize(triggered_project, opts={})
    @triggered_project = triggered_project
    @build_interval = opts[:build_interval] || 24.hours
    @next_build_time = opts[:start_time] || calculate_next_build_time
  end
  
  def build_necessary?(reasons)
    if @triggered_project.build_requested? || time_for_new_build?
      @next_build_time = calculate_next_build_time
      true
    end
  end
  
  def calculate_next_build_time
    Time.now + @build_interval
  end
  
  def time_for_new_build?
    Time.now >= @next_build_time
  end
end