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
  
  def succeed!(elapsed_time)
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-success.in#{elapsed_time}s"
  end
  
  def fail!(elapsed_time, error_message=nil)
    error_message_file = File.join(@artifacts_directory, "error.log")
    File.open(error_message_file, "w+"){|f| f.write error_message } if error_message
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-failed.in#{elapsed_time}s"
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
    match_elapsed_time(File.basename(@artifacts_directory))
  end
  
  def match_elapsed_time(file_name)
    match =  /^build-[^\.]+\.in(\d+)s$/.match(file_name)
    raise 'Could not parse elapsed time.' if !match or !$1
    $1.to_i
  end
  
  def error_message_file
    Dir["#{@artifacts_directory}/error.log"].first
  end
  
  private
  
  def read_latest_status
    return 'never_built' unless File.exist? @artifacts_directory
    match_status(@artifacts_directory).downcase
  end
  
  def match_status(dir_name)
    a = dir_name.split("-")
    return a.last.split(".").first if  a.size > 2
    return "incomplete"
  end
end