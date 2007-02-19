class InProgressBuildStatus
  include ApplicationHelper
  include ProjectsHelper

  def self.deletion_marker_file_suffix
    "_for_deletion_upon_next_refresh"
  end
  
  def self.delete_in_progress_build_status_file_if_any(project)
    deletion_marker = project.in_progress_build_status_file + InProgressBuildStatus.deletion_marker_file_suffix
    if File.exists?(deletion_marker)
      deletion_marker =~ /(.*)(#{InProgressBuildStatus.deletion_marker_file_suffix})/
      file_to_be_deleted = $1
      FileUtils.rm_f(Dir[file_to_be_deleted])
      FileUtils.rm_f(Dir[deletion_marker])
    end
  end
    
  def initialize(project)
  end

  def build_started(build)
    File.open(build.project.in_progress_build_status_file, 'w') do |aFile|
      aFile.print("#{build.label}")
    end
  end

  def build_finished(build)

    mark_file_for_deletion_upon_next_refresh(build.project.in_progress_build_status_file)
  end
  
  private
  
  def mark_file_for_deletion_upon_next_refresh(filename)
    f = File.open(filename + InProgressBuildStatus.deletion_marker_file_suffix, 'w')
    f.close
  end
end

Project.plugin :in_progress_build_status 
