ENV['BUNDLE_WITHOUT'] = 'development:test'
ENV['RAILS_ENV'] = 'production'

require 'java'

# because jruby-rack does not respect GEM_HOME/GEM_PATH set in web.xml
module LuauServer
  module RailsInitializer
    rails_root  = $servlet_context.get_real_path $servlet_context.get_init_parameter('rails.root')
    gem_path    = $servlet_context.get_real_path $servlet_context.get_init_parameter('gem.path')
    gem_home    = $servlet_context.get_real_path $servlet_context.get_init_parameter('gem.home')

    raise "Could not find context-param 'rails.root' in web.xml" unless rails_root
    raise "Could not find context-param 'gem.path' in web.xml" unless gem_path
    raise "Could not find context-param 'gem.home' in web.xml" unless gem_home

    ENV['GEM_HOME'] = gem_path
    ENV['GEM_PATH'] = gem_home
  end
end
