# BuildStatus represents the state of a build. It is used by the Dashboard and generated XML
# to provide feedback on current or old builds. It uses the build artifacts directory to determine
# the age of the build, and uses the name of that directory to indicate the status of past builds.
class BuildStatus
  # The build was a success, because the build command exited successfully.
  SUCCESS = 'success'
  
  # The build failed, because the build command exited with a non-zero status.
  FAILED = 'failed'
  
  # The build is currently running and thus incomplete.
  INCOMPLETE = 'incomplete'
  
  # The build was never begun, typically because no workers were available to pick the build up.
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
    error_message_file.open("w+") { |f| f.write error } unless error.nil?
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
    Pathname.new(@artifacts_directory).join("error.log")
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