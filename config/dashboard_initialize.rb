
# Local configuration, for example, details of the SMTP server for email notification, should be 
# written in ./config/site_config.rb. See ./config/site_config.rb_example for an example of what this file may 
# look like.
require CRUISE_DATA_ROOT + '/site_config' if File.exists?(CRUISE_DATA_ROOT + "/site_config.rb")


puts "I'm READING STUFF!!!!!!!!!!!!!!"
site_css = CRUISE_DATA_ROOT + "/site.css"
if File.exists?(site_css)
  File.open(RAILS_ROOT + "/public/stylesheets/site.css", "w") do |f|
    f << "/* this is a copy of #{site_css}, please make any changes to it there */\n\n"
    f << File.read(CRUISE_DATA_ROOT + "/site.css")
  end
end
