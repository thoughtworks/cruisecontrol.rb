class BuildStatus

  def initialize(artifacts_directory)
    @artifacts_directory = artifacts_directory 
  end
  
  def never_built?
    read_latest_status == 'never_built'
  end
  
  def succeeded?
    read_latest_status == 'success'
  end
  
  def in_progress?
    read_latest_status == 'in_progress'
  end
  
  def failed?
    read_latest_status == 'failed'
  end

  def start!
    remove_status_file
    touch_status_file("in_progress")
  end
  
  def succeed!(elapsed_time)
    remove_status_file
    touch_status_file("success.in#{elapsed_time}s")
  end
  
  def fail!(elapsed_time)
    remove_status_file
    touch_status_file("failed.in#{elapsed_time}s")
  end
    
  def created_at
    if file = status_file
      File.mtime(file)
    end
  end
  
  def to_s
    read_latest_status.to_s
  end
  
  def elapsed_time_in_progress
    in_progress? ? (Time.now - created_at).ceil : 0
  end
  
  def elapsed_time
    file = status_file
    match_elapsed_time(File.basename(file))
  end

  def match_elapsed_time(file_name)
    match =  /^build_status\.[^\.]+\.in(\d+)s$/.match(file_name)
    raise 'Could not parse elapsed time.' if !match or !$1
    $1.to_i
  end
        
  private
  
  def read_latest_status
    file = status_file
    file ? match_status(File.basename(file)).downcase : 'never_built'
  end

  def remove_status_file
    FileUtils.rm_f(Dir["#{@artifacts_directory}/build_status.*"])
  end
  
  def touch_status_file(status)
    FileUtils.touch("#{@artifacts_directory}/build_status.#{status}")
  end
  
  def status_file
    Dir["#{@artifacts_directory}/build_status.*"].first
  end
  
  def match_status(file_name)
     /^build_status\.([^\.]+)(\..+)?/.match(file_name)[1]
  end
end