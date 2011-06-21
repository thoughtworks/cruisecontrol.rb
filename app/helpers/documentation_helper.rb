module DocumentationHelper
  def render_plugin_doc(file)
    if File.directory?(file)
      if File.exists?(file + '/README')
        render :inline => markup(File.read(file + '/README'))
      else
        render :text => "this plugin has no README", :layout => false
      end
    elsif File.exists?(file)
      render :inline => markup(comments(File.read(file)))
    end
  end
  
  def markup(text)
    RedCloth.new(text).to_html
  end
  
  def comments(text)
    text = text.gsub(/^[^#].*$\n?/, '').gsub(/^# ?/, '').strip
    text.empty? ? 'this plugin has no comments' : text
  end
  
  def link_to_download(text)
    link_to text, "https://github.com/thoughtworks/cruisecontrol.rb/downloads"
  end
  
  def link_to_users_mailing_list(text)
    link_to text, "http://rubyforge.org/mailman/listinfo/cruisecontrolrb-users"
  end
  
  def link_to_developers_mailing_list(text)
    link_to text, "http://rubyforge.org/mailman/listinfo/cruisecontrolrb-developers"
  end
  
  def link_to_issue_tracker(text)
    link_to text, 'https://github.com/thoughtworks/cruisecontrol.rb/issues'
  end
  
  def link_to_issue_tracker_signup(text)
    link_to text, 'https://github.com/signup/free'
  end
end
