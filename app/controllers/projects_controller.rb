class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    @projects = Projects.load_all
    
    respond_to do |format|
      format.html
      format.js { render :action => 'refresh_projects' }
      format.rss { render :action => 'rss', :layout => false }
      format.cctray { render :action => 'cctray', :layout => false }
    end
  end
  
  def rss
    @projects = []
    @projects << Projects.find(params[:project])
    render :layout => false
  end

  def build
    render :text => 'Project not specified', :status => 404 and return unless params[:id]

    @project = Projects.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil
    @projects = Projects.load_all

    render :action => 'refresh_projects'
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