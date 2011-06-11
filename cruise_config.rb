# This is the file that CruiseControl uses to configure its own build at 
# http://cruisecontrolrb.thoughtworks.com/.

Project.configure do |project|
  project.email_notifier.emails = ["cruisecontrolrb@thoughtworks.com"] if Socket.gethostname =~ /cruisecontrolrb.thoughtworks.com/
end
