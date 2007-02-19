class Configuration

  @projects_directory = File.expand_path(File.join(RAILS_ROOT, 'projects'))
  @default_polling_interval = 10.seconds
  @sleep_after_build_loop_error = 30.seconds
  @build_request_checking_interval = 5.seconds
  @context = nil

  class << self
    attr_accessor :projects_directory, :default_polling_interval, :sleep_after_build_loop_error,
                  :build_request_checking_interval, :context
  end

end
