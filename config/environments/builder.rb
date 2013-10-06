CruiseControl::Application.configure do
  CRUISE_OPTIONS[:log_file_name] = 
    "#{CruiseControl.data_root}/#{CRUISE_OPTIONS[:project_name] || "NOT_NAMED"}_builder.log"
  config.cache_classes = true
  config.paths.log = CRUISE_OPTIONS[:log_file_name]
  config.log_level = CRUISE_OPTIONS[:verbose] ? :debug : :info
  config.active_support.deprecation = :notify

  config.after_initialize do
    CruiseControl.require_site_config_if_needed
  end
end