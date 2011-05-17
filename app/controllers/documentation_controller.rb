class DocumentationController < ApplicationController
  caches_page :get

  # TODO Fix this. Fix it hard. - SHOULD BE CONVERTED TO STATIC DOCUMENTATION.
  def get
    if params[:path].blank?
      render :template => "documentation/index", :layout => "documentation"
    elsif params[:path] == "plugin_repositories"
      render :template => "documentation/plugin_repositories"
    else
      render :template => "documentation/#{params[:path]}", :layout => "documentation"
    end
  end
  
  def plugins
    if params.has_key? :name
      @plugin_title = ActiveSupport::Inflector.titleize(params[:name].sub(/\.rb$/, ''))
      case params[:type]
      when 'builtin'
        @file = Rails.root.join('lib', 'builder_plugins', params[:name])
      when 'installed'
        @file = Configuration.plugins_root.join(params[:name])
      when 'available'
        #???
      end
    end
  end

end
