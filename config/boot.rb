# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'rubygems'

ENV['GEM_PATH'] = File.expand_path('../../vendor/unpacked', __FILE__)
Gem.clear_paths
  
require 'bundler/setup'