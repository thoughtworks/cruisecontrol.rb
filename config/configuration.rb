class Configuration
  @default_page = {:controller => 'projects', :action => 'index'}
  @projects_directory = File.expand_path(File.join(RAILS_ROOT, 'projects'))
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
                  :dashboard_refresh_interval, :projects_directory, :serialize_builds,
                  :serialized_build_timeout
    attr_reader :dashboard_url

    # non-published configuration options (obscure stuff, mostly useful for http://cruisecontrolrb.thoughtworks.com)
    attr_accessor :sleep_after_build_loop_error, :default_page, :build_request_checking_interval

    def dashboard_url=(value)
      @dashboard_url = remove_trailing_slash(value)
    end

    private

    def remove_trailing_slash(str)
      str.sub(/\/$/, '')
    end
   
  end

end

# Local configuration, for example, details of the SMTP server for email notification, should be 
# written in ./config/site_config.rb. See ./config/site_config.rb_example for an example of what this file may 
# look like.
require 'site_config' if RAILS_ENV != 'test' && File.exists?("#{RAILS_ROOT}/config/site_config.rb")
