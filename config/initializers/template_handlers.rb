class TextileTemplateHandler < ActionView::TemplateHandlers::ERB
  extend ActiveSupport::Memoizable
  
  def compile(template)
    return super + ";RedCloth.new(@output_buffer).to_html;"
  end
end

ActionView::Template.register_template_handler :red, TextileTemplateHandler
