require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require 'lib/ruby-growl'

$VERBOSE = nil

spec = Gem::Specification.new do |s|
  s.name = "ruby-growl"
  s.version = Growl::VERSION
  s.summary = "Pure-Ruby Growl Notifier"
  s.description = <<-EOF
ruby-growl allows you to perform Growl notification via UDP from machines
without growl installed (for example, non-OSX machines).

What's Growl?  Growl is a really cool "global notification system for Mac OS
X".  See http://growl.info/

See also the Ruby Growl bindings in Growl's subversion repository:
http://growl.info/documentation/growl-source-install.php

ruby-growl also contains a command-line notification tool named 'growl'.  Where possible, it isoption-compatible with growlnotify.  (Use --priority instead of -p.)
EOF

  s.files = File.read("Manifest.txt").split($\)

  s.require_path = 'lib'
  
  s.executables = ["growl"]
  s.default_executable = "growl"

  s.has_rdoc = true

  s.author = "Eric Hodel"
  s.email = "drbrain@segment7.net"
  s.homepage = "http://segment7.net/projects/ruby/growl/"
end

##
# Targets
##

desc "Run the tests"
task :default => [ :test ]

desc "Run the tests"
Rake::TestTask.new "test" do |t|
  t.libs << "test"
  t.pattern = "test/test_*.rb"
  t.verbose = true
end

desc "Build RDoc"
Rake::RDocTask.new "rdoc" do |rd|
  rd.rdoc_dir = "doc"
  rd.rdoc_files.add "lib"
  rd.main = "Growl"
end

desc "Build Packages"
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

