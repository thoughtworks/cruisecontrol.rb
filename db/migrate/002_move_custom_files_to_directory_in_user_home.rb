require 'fileutils'
include FileUtils

DATA_ROOT = ARGV[0]
RAILS_ROOT = File.expand_path(".")

if File.exists? 'projects'
  mv 'projects', DATA_ROOT + '/projects'
else
  mkdir_p DATA_ROOT + '/projects'
end

if File.exists? 'config/site_config.rb'
  mv 'config/site_config.rb', DATA_ROOT + '/site_config.rb'
elsif !File.exists? DATA_ROOT + '/site_config.rb'
  cp 'config/site_config.rb_example', DATA_ROOT + '/site_config.rb'
end

if File.exists? 'public/stylesheets/site.css'
  mv 'public/stylesheets/site.css', DATA_ROOT + '/site.css'
elsif !File.exists? DATA_ROOT + '/site.css'
  cp 'public/stylesheets/site.css_example', DATA_ROOT + '/site.css'
end

mkdir_p DATA_ROOT + '/builder_plugins'
plugins = Dir['builder_plugins/**.rb']
unless plugins.empty?
  raise "We just created a data directory at #{DATA_ROOT}.  Any builder plugins in addition to the ones in
#{RAILS_ROOT}/lib/builder_plugins need to be moved from

#{RAILS_ROOT}/builder_plugins 
to 
#{DATA_ROOT}/builder_plugins

then remove the builder_plugins/ directory (it currently contains #{plugins.inspect})"
end
