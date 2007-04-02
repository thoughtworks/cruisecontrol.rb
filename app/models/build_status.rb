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
  
  def incomplete?
    read_latest_status == 'incomplete'
  end
  
  def failed?
    read_latest_status == 'failed'
  end
  
  def start!
    remove_status_file
    touch_status_file("incomplete")
  end
  
  def succeed!(elapsed_time)
    status_message = "success.in#{elapsed_time}s"
    remove_status_file
    touch_status_file(status_message)
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-#{status_message}"
  end
  
  def fail!(elapsed_time, error_message=nil)
    status_message = "failed.in#{elapsed_time}s"
    remove_status_file
    touch_status_file(status_message, error_message)
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-#{status_message}"
  end
  
  def created_at
    File.mtime(@artifacts_directory) rescue nil
  end
  
  def timestamp
    build_dir_mtime = File.mtime(@artifacts_directory)
    begin
      build_log_mtime = File.mtime("#{@artifacts_directory}/build.log")
    rescue
      return build_dir_mtime
    end      
    build_log_mtime > build_dir_mtime ? build_log_mtime : build_dir_mtime
  end
  
  def to_s
    read_latest_status.to_s
  end
  
  def elapsed_time_in_progress
    incomplete? ? (Time.now - created_at).ceil : nil
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
  
  def status_file
    Dir["#{@artifacts_directory}/build_status.*"].first
  end
  
  private
  
  def read_latest_status
    return 'never_built' unless File.exist? @artifacts_directory
    match_status(@artifacts_directory).downcase
  end
  
  def remove_status_file
    FileUtils.rm_f(Dir["#{@artifacts_directory}/build_status.*"])
  end
  
  def touch_status_file(status, error_message=nil)
    filename = "#{@artifacts_directory}/build_status.#{status}"
    FileUtils.touch(filename)
    if error_message
      File.open(filename, "w"){|f|f.write error_message}
    end
  end
  
  def match_status(dir_name)
    a = dir_name.split("-")
    return a.last.split(".").first if  a.size > 2
    return "incomplete"
  end
end