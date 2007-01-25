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
