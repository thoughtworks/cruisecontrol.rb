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

def log_error(output)
  system("su - #{CRUISE_USER} -c 'touch #{CRUISE_HOME}/log/cruise_daemon_err.log'")
  File.open("#{CRUISE_HOME}/log/cruise_daemon_err.log", "a+"){|f| f << output + "\n\n"}
end

def start_cruise(start_cmd = "cd #{CRUISE_HOME} && ./cruise start -d")
  system("su - #{CRUISE_USER} -c 'touch #{CRUISE_HOME}/log/cruise_daemon_env.log'")
  File.open("#{CRUISE_HOME}/log/cruise_daemon_env.log", "a+"){|f| f << ENV.inspect + "\n\n"}
  start_cmd = "su - #{CRUISE_USER} -c '#{start_cmd}'" if CRUISE_USER != ENV['USER']
  output = `#{start_cmd} 2>&1`
  if $?.success?
    print output + "\n"
    exit 0
  else
    log_error(output)
    print output + "\n"
    exit 1
  end
end

def stop_cruise
  failed = false
  failed ||= !(system "mongrel_rails stop -P #{CRUISE_HOME}/tmp/pids/mongrel.pid")
  Dir["#{CRUISE_HOME}/tmp/pids/builders/*.pid"].each do |pid_file|
    pid = File.open(pid_file){|f| f.read }
    failed ||= !(system "kill -9 #{pid}")
    rm pid_file
  end
  if failed
    log_error("'stop' command failed")
    exit 1
  else
    exit 0
  end 
end
