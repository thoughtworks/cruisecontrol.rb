class BuilderStatus
  
  def initialize(project)
    @project_dir = project.path
  end

  def status
    read_status
  end

  def build_started(build)
    remove_status_file
    touch_status_file(:building)
  end
  
  def sleeping
    remove_status_file
    touch_status_file(:sleeping)
  end

  def polling_source_control
    remove_status_file
    touch_status_file(:checking_for_modifications)
  end

  def build_loop_failed
    remove_status_file
    touch_status_file(:error)
  end
  
  private
  
    def read_status
      file = status_file
      file ? File.basename(file)[15..-1].downcase.gsub('__', '').to_sym  : :sleeping
    end
  
    def remove_status_file
      FileUtils.rm_f(Dir["#{@project_dir}/builder_status.*"])
    end
    
    def touch_status_file(status)
      FileUtils.touch("#{@project_dir}/builder_status.#{status}")
    end
    
    def status_file
      Dir["#{@project_dir}/builder_status.*"].first
    end
      
end

Project.plugin :builder_status
