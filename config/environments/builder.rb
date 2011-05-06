CruiseControl::Application.configure do
  config.cache_classes = true
  config.paths.log = CRUISE_OPTIONS[:log_file_name] || 'log/builder_WITHOUT_A_NAME.log'
  config.log_level = CRUISE_OPTIONS[:verbose] ? :debug : :info
  config.active_support.deprecation = :notify

  config.after_initialize do
    CruiseControl.require_site_config_if_needed
  end
end