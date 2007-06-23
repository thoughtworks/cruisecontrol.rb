require 'redcloth_template'
ActionView::Base.register_template_handler 'red', RedCloth::Template
