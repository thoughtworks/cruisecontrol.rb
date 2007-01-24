desc "Publish the release files to RubyForge. May not work."
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