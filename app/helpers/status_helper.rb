# Re-map our project statuses to match the project statuses recognized
# by CCTray.Net
def map_project_status_to_ccnet_project_status(value)
  return "Success" if value == 'success' or value == 'building'
  return "Unknown" if value == 'never_built'
  return "Failure"
end

# Re-map our build activities to match the build activities recognized
# by CCTray.Net
def map_build_activity_to_ccnet_activity(value)
  return "CheckingModifications" if value == 'checking_for_modifications'
  return "Building" if value == 'building'
  return "Sleeping"
end