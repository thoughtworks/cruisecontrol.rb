class Configuration

  @builds_directory = File.expand_path(File.join(RAILS_ROOT, 'builds'))
  @default_polling_interval = 10.seconds
  @sleep_after_build_loop_error = 10.seconds
  class << self
    attr_accessor :builds_directory, :default_polling_interval, :sleep_after_build_loop_error
  end

end
