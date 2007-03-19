class DocumentationController < ApplicationController

  caches_page :get

  def get
    path = File.join('documentation', params[:path])
    
    if template_exists?(path)
      render :template => path
    elsif template_exists?(path + '/index')
      render :template => path + '/index'
    else
      render :status => 404, :text => 'Documentation page not found'
    end
  end
  
  def plugins
    if params.has_key? :name
      @plugin_title = Inflector.titleize(params[:name].sub(/\.rb$/, ''))
      @file = params[:type] + '/' + params[:name]
    end
  end

end
