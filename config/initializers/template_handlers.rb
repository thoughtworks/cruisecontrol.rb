class TextileTemplateHandler < ActionView::TemplateHandlers::ERB
  extend ActiveSupport::Memoizable
  
  def compile(template)
    html = RedCloth.new(template.source).to_html
    t = ActionView::Template.new(html, template.identifier, template.handler, {})
    super(t)
  end
end

ActionView::Template.register_template_handler :red, TextileTemplateHandler
