class InProgressBuildStatus
  DELETION_MARKER_FILE_SUFFIX = "_for_deletion_upon_next_refresh"
  
  def initialize(project)
  end

  def build_started(build)
    File.open(build.project.in_progress_build_status_file, 'w') do |aFile|
      aFile.print("in progress build label:#{build.label} (or some other build info)")
    end
  end

  def build_finished(build)

    mark_file_for_deletion_upon_next_refresh(build.project.in_progress_build_status_file)
  end
  
  private
  
  def mark_file_for_deletion_upon_next_refresh(filename)
    f = File.open(filename + DELETION_MARKER_FILE_SUFFIX, 'w')
    f.close
  end

end

Project.plugin :in_progress_build_status 
