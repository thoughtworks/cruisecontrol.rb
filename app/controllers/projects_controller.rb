class ProjectsController < ApplicationController
  
  verify :params => "id", :only => [:show, :build, :code],
         :render => { :text => "Project not specified",
                      :status => 404 }
  verify :params => "path", :only => [:code],
         :render => { :text => "Path not specified",
                      :status => 404 }
  def index
    @projects = Project.all
    
    respond_to do |format|
      format.html
      format.js { render :action => 'index_js' }
      format.rss { render :action => 'index_rss', :layout => false, :format => :xml }
      format.cctray { render :action => 'index_cctray', :layout => false }
    end
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

    respond_to { |format| format.js { render :action => 'index_js' } }
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
