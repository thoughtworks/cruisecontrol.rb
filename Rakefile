# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

require File.dirname(__FILE__) + '/lib/cruise_control/version'

PKG_NAME      = 'cruisecontrol'
PKG_VERSION   = CruiseControl::VERSION::STRING
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBY_FORGE_PROJECT = "cruisecontrolrb"
RUBY_FORGE_USER    = "stellsmi"


desc 'Install development dependencies via GemInstaller'
task :geminstaller do
  begin
    require 'geminstaller'
  rescue LoadError
    `gem install geminstaller`
    Gem.refresh
    require 'geminstaller'
  end
  
  GemInstaller.install("--config=#{RAILS_ROOT}/test/geminstaller.yml -gall -rall")
end

begin
  require 'tasks/rails'
rescue LoadError
  Rake::Task['geminstaller'].invoke
  Gem.refresh
  require 'tasks/rails'
end


