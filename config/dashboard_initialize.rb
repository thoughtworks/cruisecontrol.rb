site_css = CRUISE_DATA_ROOT + "/site.css"
if File.exists?(site_css)
  File.open(RAILS_ROOT + "/public/stylesheets/site.css", "w") do |f|
    f << "/* this is a copy of #{site_css}, please make any changes to it there */\n\n"
    f << File.read(CRUISE_DATA_ROOT + "/site.css")
  end
end
