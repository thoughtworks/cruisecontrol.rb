require File.expand_path('../lib/cruise_control/version', __FILE__)

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

  s.add_dependency "rails", "3.0.7"
  s.add_dependency "tzinfo", "0.3.27"
  s.add_dependency "rack", "1.2.3"
  s.add_dependency "bundler"

  s.add_dependency "httparty", "0.6.1"
  s.add_dependency "api_cache", "0.2.0"
  s.add_dependency "xml-simple", '1.0.16'
  s.add_dependency "rake"
  s.add_dependency "jquery-rails", '1.0.9'
  s.add_dependency "abstract", "1.0.0"

  s.add_development_dependency "rcov", '0.9.9'
  s.add_development_dependency "mocha", "0.9.12"
  s.add_development_dependency "rack-test"

  s.bindir = "."
  s.executables << "cruise"

  all_files = Dir.glob("**/*")
  excluded = all_files.grep(%r!(log/)|(test/)|(tmp/)|(vendor/cache)|(pkg)|(dist)|(.bundle)!)
  s.files = all_files - excluded
  s.test_files = all_files.grep(%r!(test/)!)
end