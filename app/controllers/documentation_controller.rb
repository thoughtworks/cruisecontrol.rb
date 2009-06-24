class DocumentationController < ApplicationController
  caches_page :get

  def get
    path = File.join('documentation', params[:path])

    if path == "documentation/plugin_repositories"
      render :template => path, :layout => false
    elsif template_exists?(path)
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
      case params[:type]
      when 'builtin'
        @file = File.join(RAILS_ROOT, 'lib', 'builder_plugins', params[:name])
      when 'installed'
        @file = File.join(CRUISE_DATA_ROOT, 'builder_plugins', params[:name])
      when 'available'
        #???
      end
    end
  end

end
