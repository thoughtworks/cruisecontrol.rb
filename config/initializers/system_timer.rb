# If installed, use SystemTimer to avoid git.rb causing builder to hang due to intermittent network issues.  See:
# https://cruisecontrolrb.lighthouseapp.com/projects/9150-cruise-control-rb/tickets/229-sometimes-git-hangs
# http://ph7spot.com/musings/system-timer
begin
  require 'system_timer'
  MyTimer = SystemTimer
rescue LoadError
  require 'timeout'
  MyTimer = Timeout
end