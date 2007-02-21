#
# this plugin allows the dashboard to know each builder's status and report it
#
# (this plugin is built in and needs no customization)
#
class BuilderStatus
  
  def initialize(project)
    @project = project
  end

  def status
    builder_down? ? read_status : 'builder_down'
  end

  def build_started(build)
    set_status 'building'
  end
  
  def sleeping
    set_status 'sleeping'
  end

  def polling_source_control
    set_status 'checking_for_modifications'
  end

  def build_loop_failed
    set_status 'error'
  end
  
  private
  
  def read_status
    existing_status_file = Dir["#{@project.path}/builder_status.*"].first
    if existing_status_file
      File.basename(existing_status_file)[15..-1]
    else
      'sleeping'
    end
  end

  def set_status(status)
    FileUtils.rm_f(Dir["#{@project.path}/builder_status.*"])
    FileUtils.touch("#{@project.path}/builder_status.#{status}")
  end

  def builder_down?
    ProjectBlocker.blocked?(@project)
  end

end

Project.plugin :builder_status
