# List of projects and their state in XML - to be consumed by CruiseControl.NET tray.

xml.Projects do
  @projects.each do |project|
    xml.Project(
    :name => project.name,
    :category => "",
    :activity => map_to_cctray_activity(project.builder_state_and_activity),
    :lastBuildStatus => map_to_cctray_project_status(project.last_complete_build_status),
    :lastBuildLabel => (project.last_complete_build ? project.last_complete_build.label : 'Unknown'),
    :lastBuildTime => (project.last_complete_build ? format_time(project.last_complete_build.time, :round_trip_local) : '1970-01-01T00:00:00.000000-00:00'),
    :nextBuildTime => '1970-01-01T00:00:00.000000-00:00',
    :webUrl => url_for(:only_path => false, :controller => 'projects', :action => 'show', :id => project))
  end
end
