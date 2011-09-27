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

  [ [ "rails", "3.0.7" ],
    [ "tzinfo", "0.3.27" ],
    [ "rack", "1.2.3" ],
    [ "bundler", nil ],
    [ "httparty", "0.6.1" ],
    [ "api_cache", "0.2.0" ],
    [ "xml-simple", '1.0.16' ],
    [ "rake", "0.8.7" ],
    [ "jquery-rails", '1.0.9' ],
    [ "abstract", "1.0.0" ],
  ].each do |gem, version|
    s.add_dependency gem, version
  end

  [ [ "rcov", '0.9.9' ],
    [ "mocha", "0.9.12" ],
    [ "rack-test", nil ],
  ].each do |gem, version|
    s.add_development_dependency gem, version
  end

  s.bindir = "."
  s.executables << "cruise"

  all_files = Dir.glob("**/*")
  excluded = all_files.grep(%r!(log/)|(test/)|(tmp/)|(vendor/cache)|(pkg)|(dist)|(.bundle)!)
  s.files = all_files - excluded
  s.test_files = all_files.grep(%r!(test/)!)
end