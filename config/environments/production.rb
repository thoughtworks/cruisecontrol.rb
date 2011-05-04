CruiseControl::Application.configure do
  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.active_support.deprecation = :notify

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  config.after_initialize do
    ProjectsMigration.new.migrate_data_if_needed
    CruiseControl.require_site_config_if_needed
    require Rails.root.join('config', 'dashboard_initialize')
    BuilderStarter.start_builders 
  end
end