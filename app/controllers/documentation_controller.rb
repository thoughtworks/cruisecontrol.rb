class DocumentationController < ApplicationController
  def get
    path = File.join('documentation', params[:path]).gsub(/.html$/, '')
    
    if template_exists?(path + "/index")
      redirect_to :path => (params[:path] + ['index.html'])
    elsif template_exists?(path)
      render :template => path
    else
      render_not_found
    end
  end
  
  def plugins
    if params.has_key? :name
      @plugin_title = Inflector.titleize(params[:name].sub(/\.rb$/, ''))
      @file = File.join(RAILS_ROOT, 'builder_plugins', params[:type], params[:name])
    end
  end
end
