class PollingScheduler

  def initialize(project)
    @project = project
    @custom_polling_interval = nil
    @last_build_loop_error_source = nil
    @last_build_loop_error_time = nil
  end

  def run
    while(true) do
      begin
        @project.build_if_necessary or sleep(polling_interval) 
        clean_last_build_loop_error
      rescue => e
        log_error(e) unless (same_error_as_before(e) and last_logged_less_than_an_hour_ago)
        sleep(Configuration.sleep_after_build_loop_error)
      end
    end
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

  def same_error_as_before(error)
    @last_build_loop_error_source and (error.backtrace.first == @last_build_loop_error_source)
  end
  
  def last_logged_less_than_an_hour_ago
    @last_build_loop_error_time and @last_build_loop_error_time >= 1.hour.ago
  end
  
  def log_error(error)
    begin
      Log.error(error) 
    rescue 
      STDERR.puts(error.message)
      STDERR.puts(error.backtrace.map { |l| "  #{l}"}.join("\n"))
    end
    @last_build_loop_error_source = error.backtrace.first
    @last_build_loop_error_time = Time.now
  end

  def clean_last_build_loop_error
    @last_build_loop_error_source = @last_build_loop_error_time = nil
  end
  
end
