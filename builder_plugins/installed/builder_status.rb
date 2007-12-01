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
    if builder_down?
      'builder_down'
    else
      read_status
    end
  end

  def fatal?
    %w(svn_error timed_out).include?(status)
  end
  
  def error_message
    File.open(existing_status_file){|f| f.read} rescue ""
  end
  
  def build_initiated
    set_status 'building'
  end

  def build_finished(build)
    set_status 'sleeping'
  end

  def sleeping
    set_status 'sleeping' unless status == 'build_requested'
  end
  
  def queued
    set_status 'queued'
  end
  
  def timed_out
    set_status 'timed_out'
  end
  
  def build_requested
    set_status 'build_requested'
  end

  def polling_source_control
    set_status 'checking_for_modifications' unless status == 'build_requested'
  end

  def build_loop_failed(e)
    if e.is_a?(BuilderError)
      set_status e.status, e.message
    else
      set_status 'error'
    end
  end
  
  private
  def existing_status_file
    Dir["#{@project.path}/builder_status.*"].first
  end
  
  def read_status
    if existing_status_file
      File.basename(existing_status_file)[15..-1]
    else
      'sleeping'
    end
  end

  def set_status(status, message = nil)
    FileUtils.rm_f(Dir["#{@project.path}/builder_status.*"])
    status_file = "#{@project.path}/builder_status.#{status}"
    FileUtils.touch(status_file)
    File.open(status_file, "w"){|f| f.write message } if message
  end

  def builder_down?
    !ProjectBlocker.blocked?(@project)
  end

end

Project.plugin :builder_status
