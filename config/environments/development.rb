CruiseControl::Application.configure do
  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Enable the breakpoint server that script/breakpointer connects to

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_view.debug_rjs = true
  
  # Deprecation warnings
  config.active_support.deprecation = :log

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.after_initialize do
    CruiseControl::Log.verbose = true
    CruiseControl.require_site_config_if_needed
    require Rails.root.join('config', 'dashboard_initialize')
  end
end