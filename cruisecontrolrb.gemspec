require 'rake'
require 'pathname'
require File.expand_path('../config/application', __FILE__)

GEMSPEC = Gem::Specification.new do |s|
  s.name = 'cruisecontrolrb'
  s.summary = 'CruiseControl for Ruby. Keep it simple.'
  s.version = CruiseControl::VERSION::STRING
  s.description = <<-EOS
    CruiseControl.rb provides simple continuous integration for any team or project, 
    with a focus on a pleasant out-of-the-box experience for Ruby developers.
  EOS

  s.author = 'ThoughtWorks, Inc.'
  s.email = 'cruisecontrolrb-developers@rubyforge.org'
  s.homepage = 'http://cruisecontrolrb.thoughtworks.com'
  s.has_rdoc = false
  s.bindir = "."
  s.executables << "cruise"

  s.add_dependency "bundler", "1.0.12"

  s.files = FileList[
    '[a-zA-Z0-9]*', 
    'app/**/*',
    'bin/**/*',
    'config/**/*',
    'daemon/**/*',
    'db/**/*',
    'lib/**/*.rb', 
    'public/**/*', 
    'script/**/*',
    'server_jar/**/*',
    'tasks/**/*',
    "vendor/bundle/**/*",
    ".bundle/*"
  ]

  s.test_files = FileList['test/**/*']
end