class BuildStatus
  SUCCESS = 'success'
  FAILED = 'failed'
  INCOMPLETE = 'incomplete'
  NEVER_BUILT = 'never_built'
  
  def initialize(artifacts_directory)
    @artifacts_directory = artifacts_directory 
  end
  
  def never_built?
    read_latest_status == NEVER_BUILT
  end
  
  def succeeded?
    read_latest_status == SUCCESS
  end
  
  def incomplete?
    read_latest_status == INCOMPLETE
  end
  
  def failed?
    read_latest_status == FAILED
  end
  
  def succeed!(elapsed_time)
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-#{SUCCESS}.in#{elapsed_time}s"
  end
  
  def fail!(elapsed_time, error = nil)
    File.open(error_message_file, "w+") { |f| f.write error } unless error.nil?
    FileUtils.mv @artifacts_directory, "#{@artifacts_directory}-#{FAILED}.in#{elapsed_time}s"
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
    raise 'Could not parse elapsed time' if !match or !$1
    $1.to_i
  end
  
  def error_message_file
    File.join(@artifacts_directory, "error.log")
  end
  
  private
  
  def read_latest_status
    return NEVER_BUILT unless File.exist? @artifacts_directory
    match_status(@artifacts_directory).downcase
  end
  
  def match_status(dir_name)
    status_and_time = File.basename(dir_name).split("-")[2]
    if status_and_time.nil?
      INCOMPLETE
    else
      status_and_time.split(".").first
    end
  end
end