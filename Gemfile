source "http://rubygems.org"

gem "rails", "3.2.15"
gem "tzinfo"#, "0.3.27"
gem "rack"#, "1.2.3"
gem "bundler"#, "~> 1.0.12"

gem "httparty", "0.6.1"
gem "api_cache", "0.2.0"
gem "xml-simple", '1.0.16', :require => 'xmlsimple'
gem "rake", "~> 0.9.2.2"
gem "jquery-rails", '1.0.9'
gem "abstract", "1.0.0"
gem "xmpp4r"
gem 'thin'

group :development do
  gem "rcov", '0.9.9'
  gem "mocha", :require => false#, "0.9.12", :require => false
  gem "rack-test", :require => "rack/test"
end

platform :jruby do
  gem 'jruby-openssl'
end

gem "googlecharts"

group :development do
  gem 'powder'
end

group :test do
  gem 'debugger', :platforms => :ruby_19
end

gem 'system_timer', :platforms => :ruby_18
