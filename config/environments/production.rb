# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Local configuration, for example, details of the SMTP server for email notification, should be 
# written in ./config/site_config.rb. See ./config/site_config.rb_example for an example of what this file may 
# look like.
require 'site_config' if File.exists?("#{RAILS_ROOT}/config/site_config.rb")

# Start builders after config initialization if we are running a web server here
if File.exist?("#{RAILS_ROOT}/tmp/cc_context_webapp")
  $CRUISE_CONTROL_CONTEXT = :webapp
  FileUtils.rm "#{RAILS_ROOT}/tmp/cc_context_webapp"
end

if $CRUISE_CONTROL_CONTEXT == :webapp
  config.after_initialize do
    BuilderStarter.start_builders $VERBOSE_MODE
  end
end