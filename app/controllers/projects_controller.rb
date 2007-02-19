class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    @projects = Projects.load_all
    
    @projects.each do |project|
      InProgressBuildStatus.delete_in_progress_build_status_file_if_any(project)
    end
    
    respond_to do |format|
      format.html
      format.js
      format.rss { render :action => 'rss', :layout => false }
    end
  end

  def build
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Projects.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil

    render :nothing => true
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