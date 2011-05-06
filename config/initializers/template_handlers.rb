class TextileTemplateHandler < ActionView::TemplateHandlers::ERB
  extend ActiveSupport::Memoizable
  
  def source
    RedCloth.new(File.read(filename)).to_html
  end
  memoize :source
end

ActionView::Template.register_template_handler :red, TextileTemplateHandler