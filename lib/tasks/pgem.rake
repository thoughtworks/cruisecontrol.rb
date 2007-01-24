desc "Publish the API documentation"
task :pgem => [:package] do
  Rake::SshFilePublisher.new("davidhh@wrath.rubyonrails.org", "public_html/gems/gems", "pkg", "#{PKG_FILE_NAME}.gem").upload
end
