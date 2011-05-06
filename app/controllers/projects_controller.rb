class ProjectsController < ApplicationController

  def index
    @projects = Project.all
    
    respond_to do |format|
      format.html
      format.js { render :action => 'index_js' }
      format.rss { render :action => 'index_rss', :layout => false, :format => :xml }
      format.cctray { render :action => 'index_cctray', :layout => false }
    end
  end

  def create
    scm = SourceControl.create(params[:project][:source_control])
    project = Project.create(params[:project][:name], scm)

    redirect_to getting_started_project_path(project.id)
  end

  def getting_started
    @project = Project.find(params[:id])
    @config_example = File.read( File.join("config", "cruise_config.rb.example") )
  end

  def show
    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    respond_to do |format|
      format.html { redirect_to :controller => "builds", :action => "show", :project => @project }
      format.rss { render :action => 'show_rss', :layout => false }
    end
  end

  def build
    render :text => 'Build requests are not allowed', :status => 403 and return if Configuration.disable_build_now

    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil
    @projects = Project.all

    respond_to do |format| 
      format.html { redirect_to :controller => "builds", :action => "show", :project => @project }
      format.js { render :action => 'index_js' }
    end
  end
  
  def code
    if Configuration.disable_code_browsing
      render :text => "Code browsing disabled" and return
    end

    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project 

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
