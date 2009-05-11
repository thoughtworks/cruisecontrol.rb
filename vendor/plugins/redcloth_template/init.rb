require File.join(File.dirname(__FILE__), 'lib', 'redcloth_template')
ActionView::Template.register_template_handler :red, ActionView::TemplateHandlers::RedClothTemplate
