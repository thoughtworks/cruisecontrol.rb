class Status
  
  RUNNING = "Running"
  NOT_RUNNING = "Not Started"
  
  def initialize(artifacts_directory)
    @artifacts_directory = artifacts_directory
  end
  
  def never_built?
    read_latest_status == :never_built
  end
  
  def succeeded?
    read_latest_status == :success
  end
  
  def failed?
    read_latest_status == :failed
  end

  def succeed!
    remove_status_file
    touch_status_file(:success)
  end
  
  def fail!
    remove_status_file
    touch_status_file(:failed)    
  end
  
  def building!
    remove_status_file
    touch_status_file(:building)
  end
  
  def created_at
    if file = status_file
      File.mtime(file)
    end
  end
  
  def to_s
    read_latest_status.to_s
  end
    
  private
  
    def read_latest_status
      file = status_file
      file ? File.basename(file)[15..-1].downcase.gsub('__', '').to_sym : :never_built
    end
  
    def remove_status_file
      FileUtils.rm_f(Dir["#{@artifacts_directory}/build_status = *"])
    end
    
    def touch_status_file(status)
      FileUtils.touch("#{@artifacts_directory}/build_status = #{status}")
    end
    
    def status_file
      Dir["#{@artifacts_directory}/build_status = *"].first
    end
  
end