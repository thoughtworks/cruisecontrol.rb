# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/rdoctask'

require 'rake/packagetask'
require 'rake/gempackagetask'

CruiseControl::Application.load_tasks

PKG_NAME      = 'cruisecontrol'
PKG_VERSION   = CruiseControl::VERSION::STRING
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"