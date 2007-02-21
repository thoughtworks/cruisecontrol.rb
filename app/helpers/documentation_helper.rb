module DocumentationHelper
  def render_plugin_doc(file)
    if File.directory?(file)
      if File.exists?(file + '/README')
        render :inline => markup(File.read(file + '/README')), :layout => true
      else
        render :text => "this plugin has no README", :layout => true
      end
    elsif File.exists?(file) 
      render :inline => markup(comments(File.read(file))), :layout => true
    end
  end
  
  def markup(text)
    RedCloth.new(text).to_html
  end
  
  def comments(text)
    text = text.gsub(/^[^#].*$\n?/, '').gsub(/^#+ */, '').strip
    text.empty? ? 'this plugin has no comments' : text
  end
end
