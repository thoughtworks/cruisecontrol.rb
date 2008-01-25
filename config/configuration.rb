class Configuration
  @default_page = {:controller => 'projects', :action => 'index'}
  @default_polling_interval = 20.seconds
  @sleep_after_build_loop_error = 30.seconds
  @build_request_checking_interval = 5.seconds
  @dashboard_refresh_interval = 5.seconds
  @dashboard_url = nil
  @email_from = 'cruisecontrol@thoughtworks.com'
  @disable_build_now = false
  @serialize_builds = false
  @serialized_build_timeout = 1.hour

  class << self
    # published configuration options (mentioned in config/site_config.rb.example)
    attr_accessor :default_polling_interval, :disable_build_now, :email_from,
                  :dashboard_refresh_interval, :serialize_builds,
                  :serialized_build_timeout
    attr_reader :dashboard_url

    # non-published configuration options (obscure stuff, mostly useful for http://cruisecontrolrb.thoughtworks.com)
    attr_accessor :sleep_after_build_loop_error, :default_page, :build_request_checking_interval

    def dashboard_url=(value)
      @dashboard_url = remove_trailing_slash(value)
    end
    
    def projects_directory=(value)
      raise "projects directory may no longer be set, projects now live in ~/.cruise/projects by default.\n" +
            "To configure this, set the CRUISE_DATA_ROOT environment variable"
    end

    private

    def remove_trailing_slash(str)
      str.sub(/\/$/, '')
    end
   
  end

end