Rake::PackageTask.new("cruisecontrolrb", CruiseControl::VERSION::STRING) do |p|
  p.need_tar = true
  p.need_zip = true
  p.package_files.include("**/*").exclude("log/**").exclude("tmp/**").exclude("doc/**").exclude("pkg")
end
