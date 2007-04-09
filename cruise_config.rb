# this is the file that cruise control uses to configure its own cruise build at 
# http://cruisecontrolrb.thoughtworks.com/
#   simple, ain't it

Project.configure do |project|
  project.email_notifier.emails = ["cruisecontrol-developers@rubyforge.org"]
#  project.triggered_by successful_build_of(:cruise_control_fast)
end
