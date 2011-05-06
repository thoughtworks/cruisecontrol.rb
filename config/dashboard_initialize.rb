site_css = Configuration.data_root.join("site.css")
if File.exists?(site_css)
  copy_of_site_css = Rails.root.join('public', 'stylesheets', 'site.css')
  begin
    File.open(copy_of_site_css, "w") do |f|
      f << "/* this is a copy of #{site_css}, please make any changes to it there */\n\n"
      f << File.read(site_css)
    end
  rescue
    CruiseControl::Log.warn("Could not copy contents of #{site_css} to #{copy_of_site_css}")
  end
end
