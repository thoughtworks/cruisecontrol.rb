# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# CC.rb: this line should stay commented out
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.11' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
ABSOLUTE_RAILS_ROOT = File.expand_path(RAILS_ROOT) unless defined? ABSOLUTE_RAILS_ROOT

Rails::Initializer.run do |config|
  def find_home
    looks_like_windows = (Config::CONFIG["target_os"] =~ /32/)

    if ENV['HOME']
      ENV['HOME']
    elsif ENV['USERPROFILE']
      ENV['USERPROFILE'].gsub('\\', '/')
    elsif ENV['HOMEDRIVE'] && ENV['HOMEPATH']
      "#{ENV['HOMEDRIVE']}:#{ENV['HOMEPATH']}".gsub('\\', '/')
    else
      begin
        File.expand_path("~")
      rescue StandardError => ex
        looks_like_windows ? "C:/" : "/"
      end
    end
  end

  unless defined? CRUISE_DATA_ROOT
    if ENV['CRUISE_DATA_ROOT']
      CRUISE_DATA_ROOT = ENV['CRUISE_DATA_ROOT']
    else
      CRUISE_DATA_ROOT = File.join(find_home, ".cruise")
    end
    puts "cruise data root = '#{CRUISE_DATA_ROOT}'"
  end

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  config.frameworks -= [ :active_record, :active_resource ]

  # Add additional load paths for your own custom dirs
  config.autoload_paths << "#{CRUISE_DATA_ROOT}/builder_plugins"
  config.autoload_paths << "#{RAILS_ROOT}/lib/builder_plugins"
  
  config.after_initialize do
    require RAILS_ROOT + '/config/configuration'
  end
end

require RAILS_ROOT + '/lib/cruise_control/version'
require 'smtp_tls'
require 'date'
require 'fileutils'

# get rid of cached pages between runs
FileUtils.rm_rf RAILS_ROOT + "/public/builds"
FileUtils.rm_rf RAILS_ROOT + "/public/documentation"

BuilderPlugin.load_all
