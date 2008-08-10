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

def start_cruise(start_cmd = "cd #{CRUISE_HOME} && ./cruise start -d")
  log(:env, ENV.inspect)
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
  failed ||= !(system "mongrel_rails stop -P #{CRUISE_HOME}/tmp/pids/mongrel.pid")
  Dir["#{CRUISE_HOME}/tmp/pids/builders/*.pid"].each do |pid_file|
    pid = File.open(pid_file){|f| f.read }
    failed ||= !(system "kill -9 #{pid}")
    rm pid_file
  end
  if failed
    log(:err, "'stop' command failed")
    exit 1
  else
    exit 0
  end 
end
