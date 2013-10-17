require 'redcloth'

class TextileTemplateHandler < ActionView::Template::Handlers::ERB
  
  def compile(template)
    return super + ";redcloth = RedCloth.new(@output_buffer); redcloth.hard_breaks = false; redcloth.to_html;"
  end
end

ActionView::Template.register_template_handler :red, TextileTemplateHandler

