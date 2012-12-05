# CruiseControl.rb shows builds by their commit number . For git , this doesn't represent a sequential number . This plugin adds a sequential build number . 
#
#
class SequentialBuildLogger < BuilderPlugin
  attr_accessor :enabled
  attr_accessor :show_in_artifacts

  
  def initialize(project)
    @enabled = false 
    @show_in_artifacts = true
  end

  def build_finished(build)
    add_build(build) if @enabled
  end

  
  private

  def add_build(build)
    begin
      current_dir = Rails.root.join('lib', 'builder_plugins', 'sequential_build_logger').to_s
      #Log file and html file in project path
      project_build_sequence_log = "#{build.project.path}/build_sequence.log"
      project_build_sequence_log_html = "#{build.project.path}/build_sequence.html"

      unless File.exists?(project_build_sequence_log)
        open_build_sequence_log_and_add_first_row(project_build_sequence_log, build)
        # Copy html template to project path
        FileUtils.cp "#{current_dir}/index.html" , project_build_sequence_log_html
        open_html_file_and_add_first_row(project_build_sequence_log_html , build)
      else
        lastline_in_build_sequence_log = `tail -1 #{project_build_sequence_log}`
        last_build_no = lastline_in_build_sequence_log.split(':')[0].to_i
        open_build_sequence_log_and_add_next_row(project_build_sequence_log , last_build_no , build)
        open_html_file_and_add_next_row(project_build_sequence_log_html , last_build_no , build)
      end
      CruiseControl::Log.event("Sequential build number added to file - #{project_build_sequence_log}" , :info)
      
      if @show_in_artifacts
        destination_dir = "#{build.artifacts_directory}/build_sequence"
        destination_html_file = destination_dir + "/index.html"
        FileUtils.mkdir_p destination_dir 
        FileUtils.cp project_build_sequence_log_html , destination_html_file
        File.open(destination_html_file, "a") do |f| 
          f.write "</table>"
        end 
        FileUtils.cp_r Rails.root.join('lib', 'builder_plugins', 'sequential_build_logger' , 'tablecloth').to_s , destination_dir
      end
    rescue Exception => e
      CruiseControl::Log.event("Sequential build number was not added to file - #{e.inspect}" , :error)
    end
  end

  def open_build_sequence_log_and_add_first_row(project_build_sequence_log,build)
        File.open(project_build_sequence_log, "w") do |f| 
          f.write "1:#{build.label}\n"
        end 
  end

  def open_html_file_and_add_first_row(project_build_sequence_log_html, build)
    File.open(project_build_sequence_log_html, "a") do |f| 
      f.write "<table cellspacing='0' cellpadding='0'>" +
               "<tr>" +
               "<th>Build No</th><th>Commit No</th>" +
               "</tr>" +
               "<tr>" +
               "<td>#{1}</td><td #{cell_class(build)}>#{build.label}</td>" +
               "</tr>"
    end 
  end

  def open_build_sequence_log_and_add_next_row(project_build_sequence_log, last_build_no, build)
      File.open(project_build_sequence_log, "a+") do |f| 
        f.write "#{last_build_no + 1}:#{build.label}\n"
      end 
  end

  def open_html_file_and_add_next_row(project_build_sequence_log_html, last_build_no , build)
    File.open(project_build_sequence_log_html, "a") do |f| 
      f.write  "<tr>" +
               "<td>#{last_build_no + 1}</td><td #{cell_class(build)}>#{build.label}</td>" +
               "</tr>"
    end 
  end

  def cell_class(build)
      style = "class = 'failed_build'" #build.failed? ? "class = 'failed_build'" : "" 
  end

end

Project.plugin :sequential_build_logger
