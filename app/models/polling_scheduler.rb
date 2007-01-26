class PollingScheduler

  def initialize(project)
    @project = project
    @custom_polling_interval = nil
  end

  def run
    @project.build_if_necessary or sleep(polling_interval) while(true)
  end

  def polling_interval
    @custom_polling_interval or Configuration.default_polling_interval
  end
  
  def polling_interval=(value)
    begin
      value = value.to_i
    rescue 
      raise "Polling interval value #{value.inspect} could not be converted to a number of seconds"
    end
    raise "Polling interval of #{value} seconds is too small (min. 5 seconds)" if value < 5.seconds
    raise "Polling interval of #{value} seconds is too big (max. 24 hours)" if value > 24.hours
    @custom_polling_interval = value
  end

  def memento
    @custom_polling_interval ? 
      "project.scheduler.polling_interval = #{@custom_polling_interval}.seconds" : 
      nil
  end

end
