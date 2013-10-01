# CruiseControl.rb shows builds by their commit number . For git , this doesn't represent a sequential number . This plugin adds a sequential build number . 
#
#
class ReleaseTagLogger < BuilderPlugin
  attr_accessor :enabled
  attr_accessor :show_in_artifacts

  
  def initialize(project)
    @enabled = true 
    @show_in_artifacts = true
    @current_dir = Rails.root.join('lib', 'builder_plugins', 'release_tag_logger').to_s
  end

  def release_tagged(revision , tag_label, build)
    @project_release_tag_log = "#{build.project.path}/release_tag.log"
    if @enabled
      remove_existing_tag(tag_label)
      add_tag(revision , tag_label)
      move_tag_log_to_artifacts(build)
    end
  end

  
  private

  def remove_existing_tag(tag)
    begin
      create_temp_file_without_tag_command = "grep -v \"^#{tag},\" #{@project_release_tag_log} > tmpfile" 
      move_temp_file_to_release_tag_log_command = "mv tmpfile #{@project_release_tag_log}" 
      system(create_temp_file_without_tag_command)
      system(move_temp_file_to_release_tag_log_command)
    rescue Exception => e
      CruiseControl::Log.event("Existing release tag was not removed from file - #{e.inspect}" , :error)
    end
  end

  def add_tag(revision , tag)
    File.open(@project_release_tag_log, "a") do |f| 
      f.write "#{tag},#{revision},#{Time.now}\n"
    end 
  end

  def move_tag_log_to_artifacts(build)
    destination_dir = "#{build.artifacts_directory}/release_tags"
    FileUtils.mkdir_p destination_dir unless File.directory?(destination_dir) 
    FileUtils.cp @current_dir + '/index.html' , destination_dir
    FileUtils.cp_r @current_dir + '/tablecloth' , destination_dir
    FileUtils.cp @project_release_tag_log , destination_dir
  end


end

Project.plugin :release_tag_logger
