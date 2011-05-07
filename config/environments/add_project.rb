CruiseControl::Application.configure do |config|
  config.active_support.deprecation = :notify
  
  # No special settings required
  config.after_initialize do
    CruiseControl.require_site_config_if_needed
  end
end