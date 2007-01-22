# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'

require 'tasks/rails'

require File.dirname(__FILE__) + '/lib/cruisecontrol/version'

PKG_NAME      = 'cruisecontrol'
PKG_VERSION   = CruiseControl::VERSION::STRING
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

RUBY_FORGE_PROJECT = "cruisecontrolrb"
RUBY_FORGE_USER    = "stellsmi"

# Create compressed packages
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.summary = "Continuous Integration Server for Ruby."
  s.description = %q{Continuous Integration made easy.}
  s.version = PKG_VERSION

  s.author = "ThoughtWorks"
  s.email = "jeremystellsmith@gmail.com"
  s.rubyforge_project = RUBY_FORGE_PROJECT
  s.homepage = "http://#{RUBY_FORGE_PROJECT}.rubyforge.org"

  s.has_rdoc = false
#  s.requirements << 'none'
  s.require_path = 'lib'
#  s.autorequire = 'action_mailer'

  s.default_executable = 'cruise'
  s.executables = ['cruise']

  s.files = [ "Rakefile", "README", "CHANGELOG", "LICENSE" ] +
            Dir.glob( "{bin,app,config,lib,public,script,test}/**/*" ) +
            Dir.glob( "{bin,app,config,lib,public,script,test}/**/.svn/*" ) +
            Dir.glob( "vendor/**/*" ).delete_if { |item| item.include?( "\.svn" ) }
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

desc "Publish the API documentation"
task :pgem => [:package] do
  Rake::SshFilePublisher.new("davidhh@wrath.rubyonrails.org", "public_html/gems/gems", "pkg", "#{PKG_FILE_NAME}.gem").upload
end

def myexec(cmd)
  puts "> #{cmd}"
  puts `cmd`
end

desc "Publish the release files to RubyForge."
task :release do
#task :release => [ :package ] do
  require 'rubyforge'

  options = {"cookie_jar" => RubyForge::COOKIE_F}
  puts "Enter rubyforge password:"
  options["password"] = $stdin.gets.strip
  ruby_forge = RubyForge.new(File.dirname(__FILE__) + "/config/rubyforge.yml", options)
  ruby_forge.login

  files = %w( tgz zip ).collect {|ext| "pkg/#{PKG_FILE_NAME}.#{ext}"}
  puts "Releasing #{files.collect{|f| File.basename(f)}.join(", ")}..."
  ruby_forge.add_release(RUBY_FORGE_PROJECT, PKG_NAME, PKG_VERSION, *files)
end