class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    @projects = Projects.load_all
    
    respond_to do |format|
      format.html
      format.js { render :action => 'index_js' }
      format.rss { render :action => 'index_rss', :layout => false }
      format.cctray { render :action => 'index_cctray', :layout => false }
    end
  end

  # Projects#show serves RSS feed for a specific project. So far, we have no HTML view associated with one project
  def show
    render :text => 'Project not specified', :status => 404 and return unless params[:id]

    project = Projects.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless project

    @projects = [project]
    respond_to do |format|
      format.html { redirect_to :controller => "builds", :action => "show", :project => project.name }
      format.rss { render :action => 'index_rss', :layout => false }
    end
  end

  def build
    render :text => 'Project not specified', :status => 404 and return unless params[:id]

    @project = Projects.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil
    @projects = Projects.load_all

    render :action => 'index_js'
  end
  
  def code
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    render :text => 'Path not specified', :status => 404 and return unless params[:path]

    @project = Projects.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project 

    path = File.join(@project.path, 'work', params[:path])
    @line = params[:line].to_i if params[:line]
    
    if File.directory?(path)
      render :text => 'Viewing of source directories is not supported yet', :status => 500 
    elsif File.file?(path)
      @content = File.read(path)
    else
      render_not_found
    end
  end
  
end