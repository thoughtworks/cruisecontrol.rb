# TODO: Should we rename the CruiseControl.rb statuses to match those of
# CruiseControl.NET or re-map them here?
def map_project_status_to_ccnet_project_status(value)
  return "Success" if value == :success.to_s or value == :building.to_s
  return "Unknown" if value == :never_built.to_s
  return "Failure"
end

def map_build_activity_to_ccnet_activity(value)
  return "CheckingModifications" if value == :checking_for_modifications
  return "Building" if value == :building
  return "Sleeping"
end