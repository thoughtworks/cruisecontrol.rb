require 'fileutils'

class ProjectConfigTracker

  attr_accessor :central_config_file, :central_contents, :local_config_file, :local_contents, :config_file_inside_config_folder, :config_contents_inside_config_folder

  def initialize(project_path)
    @central_config_file = File.expand_path(File.join(project_path, 'work', 'cruise_config.rb'))
    @config_file_inside_config_folder = File.expand_path(File.join(project_path, 'work', 'config', 'cruise_config.rb'))
    @local_config_file = File.expand_path(File.join(project_path, 'cruise_config.rb'))
    update_contents
  end

  def config_modified?
    old_contents = [@central_contents, @config_contents_inside_config_folder, @local_contents]
    update_contents
    [@central_contents, @config_contents_inside_config_folder, @local_contents] != old_contents
  end

  def update_contents
    @central_contents = File.exist?(@central_config_file) ? File.read(@central_config_file) : nil
    @config_contents_inside_config_folder = File.exist?(@config_file_inside_config_folder) ? File.read(@config_file_inside_config_folder) : nil
    @local_contents = File.exist?(@local_config_file) ? File.read(@local_config_file) : nil
  end

end
