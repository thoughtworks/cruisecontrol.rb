#TODO: Should we rename the CruiseControl.rb statuses to match those in CruiseControl.NET?
def map_project_status_to_ccnet_project_status(value)
  return "Success" if value == :success
  return "Unknown" if value == :never_built
  return "Failure"
end

def map_build_activity_to_ccnet_activity(value)
  return "CheckingModifications" if value == :checking_for_modifications
  return "Building" if value == :building
  return "Sleeping"
end