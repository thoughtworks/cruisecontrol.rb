# Features of this script:
# * No need to modify, configurable via calling script
# * Runs as correct user even on system boot
# * Allows control over cruise environment and start command
# * Logs environment and startup errors to help debug failures when cruise is started via system boot
# * Returns correct return codes from cruise start/stop commands (but there are still issues, see http://tinyurl.com/69ary5)
# * Ensures log files are owned by cruise user, not root

require "fileutils"
include FileUtils

require "rubygems"

begin
  gem 'mongrel'
rescue => e
  puts "Error: daemon mode of CC.rb requires mongrel installed"
  exit 1
end

def log(log_suffix, output)
  init_log_cmd = "touch #{CRUISE_HOME}/log/cruise_daemon_#{log_suffix}.log"
  system(su_if_needed(init_log_cmd))
  File.open("#{CRUISE_HOME}/log/cruise_daemon_#{log_suffix}.log", "a+"){|f| f << output + "\n\n"}
end

def su_if_needed(cmd)
  return "su - #{CRUISE_USER} -c '#{cmd}'" if CRUISE_USER != ENV['USER']
  cmd
end

def cruise_pid_file
  "#{CRUISE_HOME}/tmp/pids/mongrel.pid"
end

def read_cruise_pid
  return File.open(cruise_pid_file){|f| f.read } if File.exist?(cruise_pid_file)
  nil
end

def start_cruise(start_cmd = "cd #{CRUISE_HOME} && ./cruise start -d")
  log(:env, ENV.inspect)

  # remove cruise pid file if process is no longer running
  cruise_pid = read_cruise_pid
  if cruise_pid
    cruise_process = `ps -ea -o 'pid'`.grep(/#{cruise_pid}/).first
    FileUtils.rm(cruise_pid_file) unless cruise_process
  end

  output = `#{su_if_needed(start_cmd)} 2>&1`
  if $?.success?
    print output + "\n"
    exit 0
  else
    log(:err, output)
    print output + "\n"
    exit 1
  end
end

def stop_cruise
  failed = false
  cruise_pid = read_cruise_pid
  unless cruise_pid
    error_msg = "unable to read cruisecontrol.rb pid file #{cruise_pid_file}, cannot stop"
    log(:err, error_msg)
    print error_msg + "\n"
    exit 1
  end
  cruise_process = `ps -ea -o 'pid pgid command'`.grep(/^\s*#{cruise_pid}\s+\d+\s+.*/).first
  cruise_process =~ /^\s*#{cruise_pid}\s+(\d+)\s+(.*)/
  cruise_process_group = $1
  cruise_process_command = $2
  unless cruise_process_group  =~ /^\d+$/
    error_msg = "unable to find cruise process #{cruise_pid}, cannot stop"
    log(:err, error_msg)
    print error_msg + "\n"
    exit 1
  end

  cruise_child_processes = `ps -ea -o 'pid pgid command'`.grep(/^\s*\d+\s+#{cruise_process_group}\s+/)

  print("Killing cruise process #{cruise_pid}: #{cruise_process_command}\n")
  failed ||= !(system "mongrel_rails stop -P #{cruise_pid_file}")

  cruise_child_processes.each do |child_process|
    child_process =~ /^\s*(\d+)\s+#{cruise_process_group}\s+(.*)/
    child_pid = $1
    next if child_pid == cruise_pid
    child_args = $2
    print("Killing child process #{child_pid}: #{child_args}\n")
    system "kill -9 #{child_pid}"
  end

  Dir["#{CRUISE_HOME}/tmp/pids/builders/*.pid"].each do |pid_file|
    pid = File.open(pid_file){|f| f.read }
    rm pid_file
  end

  if failed
    log(:err, "'stop' command failed")
    exit 1
  else
    exit 0
  end 
end
