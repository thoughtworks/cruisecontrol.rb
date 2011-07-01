class Configuration
  @default_polling_interval = 20.seconds
  @sleep_after_build_loop_error = 30.seconds
  @build_request_checking_interval = 5.seconds
  @dashboard_refresh_interval = 30.seconds
  @dashboard_url = nil
  @email_from = 'cruisecontrol@thoughtworks.com'
  @disable_admin_ui = false
  @serialize_builds = false
  @serialized_build_timeout = 3.hour
  @git_load_new_changesets_timeout = 5.minutes
  @build_history_limit = 30
  @max_file_display_length = 100.kilobytes

  class << self
    # published configuration options (mentioned in config/site_config.rb.example)
    attr_accessor :default_polling_interval, :disable_admin_ui, :email_from,
                  :dashboard_refresh_interval, :serialize_builds,
                  :serialized_build_timeout, :git_load_new_changesets_timeout,
                  :disable_code_browsing, :build_history_limit, :max_file_display_length
    attr_reader :dashboard_url

    # non-published configuration options (obscure stuff, mostly useful for http://cruisecontrolrb.thoughtworks.com)
    attr_writer :build_request_checking_interval, :sleep_after_build_loop_error

    def data_root=(root)
      @data_root = Pathname.new(root)
    end

    def data_root
      @data_root ||= CruiseControl.data_root
    end

    def disable_build_now=(flag)
      puts "DEPRECATED: Please use Configuration.disable_admin_ui instead of disable_build_now to disable administration features in the UI."
      @disable_admin_ui = flag
    end

    def projects_root
      self.data_root.join("projects")
    end

    def plugins_root
      self.data_root.join("builder_plugins")
    end

    def dashboard_url=(value)
      @dashboard_url = remove_trailing_slash(value)
    end
    
    def sleep_after_build_loop_error
      @sleep_after_build_loop_error
    end

    def build_request_checking_interval
      @build_request_checking_interval.to_i
    end

    private

    def remove_trailing_slash(str)
      str.sub(/\/$/, '')
    end
   
  end

end
