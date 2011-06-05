Rake::PackageTask.new("cruisecontrolrb", CruiseControl::VERSION::STRING) do |p|
  p.need_tar = true
  p.need_zip = true
  
  p.package_files.include("**/**")
  
  
  %w(log/** tmp/** pkg/** vendor/jruby/** vendor/cache/** vendor/java/** server_jar/** vendor/**/cache/**).each do |f|
    p.package_files.exclude(f)
  end
end
