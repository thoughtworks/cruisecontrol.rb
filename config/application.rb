require File.expand_path('../boot', __FILE__)
require File.expand_path('../../lib/cruise_control/version', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "rails/test_unit/railtie"

require 'fileutils'
require 'xmlsimple'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module CruiseControl
  def self.home_directory
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
  
  def self.require_site_config_if_needed
    require self.data_root.join('site_config') if self.data_root.join('site_config.rb').exist?
  end
  
  def self.data_root
    @data_root ||= Pathname.new( ENV['CRUISE_DATA_ROOT'] || File.join(CruiseControl.home_directory, ".cruise") )
  end
  
  class Application < Rails::Application
    # Add additional load paths for your own custom dirs
    config.autoload_paths << Rails.root.join('lib').to_s
    config.autoload_paths << Rails.root.join('lib', 'builder_plugins').to_s
    config.autoload_paths << CruiseControl.data_root.join('builder_plugins').to_s
    
    config.after_initialize do
      require Rails.root.join('config', 'configuration')
      
      # get rid of cached pages between runs
      FileUtils.rm_rf Rails.root.join('public', 'builds')
      FileUtils.rm_rf Rails.root.join('public', 'documentation')
      FileUtils.rm_rf Rails.root.join('public', 'documentation.html')

      BuilderPlugin.load_all
    end

    config.action_view.javascript_expansions[:defaults] = ['rails', 'jquery', 'jquery_ujs']
  end
end

unless defined? CRUISE_DATA_ROOT
  CRUISE_DATA_ROOT = CruiseControl.data_root.to_s
  puts "cruise data root = '#{CRUISE_DATA_ROOT}'"
end