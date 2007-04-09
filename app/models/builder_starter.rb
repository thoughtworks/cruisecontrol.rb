require 'singleton'
require 'fileutils'

class BuilderStarter

  include FileUtils
  
  @@run_builders_at_startup = true;
  
  def self.run_builders_at_startup=(value)
    @@run_builders_at_startup = value
  end

  def self.start_builders
    if @@run_builders_at_startup
      Projects.load_all.each do |project|
        begin_builder project.name
      end
    end
  end
  
  def self.begin_builder(project_name)
    verbose_option = $VERBOSE_MODE ? " --trace" : ""
    cruise_executable = File.join(RAILS_ROOT, (Platform.family == 'mswin32' ? 'cruise.cmd' : 'cruise'))
    command = "\"#{cruise_executable}\" build #{project_name}#{verbose_option}"
    Platform.create_child_process(project_name, command)
  end
  
end