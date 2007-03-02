# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Enable the breakpoint server that script/breakpointer connects to
config.breakpoint_server = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_extensions         = false
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

CruiseControl::Log.verbose = true

# Local configuration, for example, details of the SMTP server for email notification, should be 
# written in ./config/site_config.rb. See ./config/site_config.rb_example for an example of what this file may 
# look like.
require 'site_config' if File.exists?("#{RAILS_ROOT}/config/site_config.rb")