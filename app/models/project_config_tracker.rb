require 'fileutils'

class ProjectConfigTracker

  attr_accessor :central_config_file, :central_mtime, :local_config_file, :local_mtime

  def initialize(project_path)
    @central_config_file = File.expand_path(File.join(project_path, 'work', 'cruise_config.rb'))
    @local_config_file = File.expand_path(File.join(project_path, 'cruise_config.rb'))
    update_timestamps
  end

  def load_config
    begin
      load central_config_file if File.file?(central_config_file)
      load local_config_file if File.file?(local_config_file)
    rescue => e
      raise "Could not load project configuration: #{e.message} in #{e.backtrace.first}"
    end
    self
  end

  def config_modified?
    old_timestamps = [@central_mtime, @local_mtime]
    update_timestamps
    [@central_mtime, @local_mtime] != old_timestamps
  end

  def update_timestamps
    @central_mtime = File.exist?(@central_config_file) ? File.mtime(@central_config_file) : nil
    @local_mtime = File.exist?(@local_config_file) ? File.mtime(@local_config_file) : nil
  end

end

