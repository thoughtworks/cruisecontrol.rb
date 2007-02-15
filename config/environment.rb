# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.1' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here


  module ActiveRecord
    # just so that WhinyNil doesn't complain about const missing
    class Base
      # and just so that ActiveRecordStore can load (even though we dont use it either
      def self.before_save(*args) end 
      # and just so controller generator can do its stuff 
      def self.pluralize_table_names() true; end 
      # and just so that Dispatcher#reset_application works
      def self.reset_subclasses() end
      # and just so that Dispatcher#prepare_application works
      def self.verify_active_connections!() end
      # and just so that Dispatcher#reset_application! works so Webrick (unlike Mongrel) stops bombing out
      def self.clear_reloadable_connections!() end
      # and just so that benchmarking's render() works 
      def self.connected?() false; end
      # and just so that Initializer#load_observers works
      def self.instantiate_observers; end
    end
  end

  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :active_record, :action_web_service ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  config.load_paths << "#{RAILS_ROOT}/builder_plugins/installed"
  config.load_paths << "vendor/RedCloth-3.0.4/lib"

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # See Rails::Configuration for more options
end

# Include your application configuration below

require 'cruise_control/version'

# Local configuration, for example, details of the SMTP server for email notification, should be 
# written in ./config/site_config.rb. See ./config/site_config.rb_example for an example of what this file may 
# look like.
require 'site_config' if File.exists?("#{RAILS_ROOT}/config/site_config.rb")