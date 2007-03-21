Project.configure do |project|
#  project.email_notifier.emails = ["not@exist.com"]
  
  if project.name.include? "quick"
    project.build_command = 'dir'
  else
    project.rake_task = 'cruise'
  end
end
p "I'm now building"
