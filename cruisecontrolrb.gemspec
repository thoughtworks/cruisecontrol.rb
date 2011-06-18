require 'rake'
require 'pathname'
require Pathname.new(__FILE__).expand_path.dirname.join('lib', 'cruise_control', 'version')

Gem::Specification.new do |s|
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

  s.files = FileList[
    '[A-Z]*', 
    'app/**/*.rb', 
    'bin/**/*',
    'config/**/*',
    'daemon/**/*',
    'db/**/*',
    'lib/**/*.rb', 
    'public/**/*', 
    'script/**/*',
    'server_jar/**/*',
    'tasks/**/*',
    "vendor/#{RUBY_ENGINE}/**/*"
  ]

  s.test_files = FileList['test/**/*']
end