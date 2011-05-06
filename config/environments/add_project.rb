CruiseControl::Application.configure do
  # No special settings required
  config.after_initialize do
    CruiseControl.require_site_config_if_needed
  end
end