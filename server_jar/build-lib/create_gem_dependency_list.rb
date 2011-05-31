# creates the gem dependency list
# looks up the Gemfile to exclude development and test gems
# most of this was stolen from warbler

require 'rubygems'
require 'bundler'

# unless defined?(JRUBY_VERSION)
#   $stderr.puts 'JRuby required to run this'
#   abort
# end

unless ARGV.length == 2
  $stderr.puts %Q{usage: jruby #{$0} GEM_FILE OUTPUT_DIR}
  abort
end

gem_file   = File.expand_path(ARGV[0])
output_dir = File.expand_path(ARGV[1])

FileUtils.mkdir_p(output_dir)
puts "*** Generating list of gem dependencies in #{output_dir}"

gemfile = Pathname.new(gem_file).expand_path
root = gemfile.dirname
lockfile = root.join('Gemfile.lock')
definition = Bundler::Definition.build(gemfile, lockfile, nil)

# exclude any development and test gems
groups = definition.groups.map {|g| g.to_sym} - [:development, :test]

# that's a list of the gemspecs
gems = definition.specs_for(groups).to_a

# figure out the gem paths
gem_fullnames = gems.collect(&:full_name)
specfication_files = gems.collect{|g| "#{g.full_name}.gemspec"}

open("#{output_dir}/gem_paths.files.txt", 'w') do |f|
  # generate a file containing the glob patterns
  puts "*** Writing to #{f.path}"
  f.puts(gem_fullnames.collect{|name| "#{name}/**/*.*"}.join("\n"))
  f.puts(gem_fullnames.collect{|name| "#{name}/**/*"}.join("\n"))
end

open("#{output_dir}/gem_specs.files.txt", 'w') do |f|
  # generate a glob file containing the list of gem spec
  puts "*** Writing to #{f.path}"
  f.puts(specfication_files)
end
