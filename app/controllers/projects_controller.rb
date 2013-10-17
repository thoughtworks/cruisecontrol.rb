class ProjectsController < ApplicationController
  include ActionView::Helpers::TextHelper

  before_filter :disable_build_triggers, :only => [:build, :kill_build]
  before_filter :disable_add_project, :only => :create
  
  def index
    @projects = Project.all

    respond_to do |format|
      format.html do
        if request.xhr?
          render_projects_partial(@projects)
        else
          render 'index'
        end
      end
      format.rss { render :action => 'index_rss', :layout => false, :format => :xml }
      format.cctray { render :action => 'index_cctray', :layout => false }
      format.json { render :json => @projects.map { |p| project_to_attributes(p) } }
    end
  end

  def create
    scm = SourceControl.create(params[:project][:source_control])
    project = Project.create(params[:project][:name], scm)
    redirect_to getting_started_project_path(project.id)
  rescue ArgumentError => e
    redirect_to new_project_path, :flash => {:notice => e.message}
  end

  def getting_started
    @project = Project.find(params[:id])
    @config_example = File.read( Rails.root.join("config", "cruise_config.rb.example") )
  end

  def show
    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    respond_to do |format|
      format.html { redirect_to :controller => "builds", :action => "show", :project => @project }
      format.rss { render :action => 'show_rss', :layout => false }
      format.json { render :json => project_to_attributes(@project) }
    end
  end

  def build
    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.request_build rescue nil

    respond_to do |format|
      format.html do
        if request.xhr?
          render_projects_partial(Project.all)
        else
          redirect_to :controller => "builds", :action => "show", :project => @project
        end
      end
    end
  end

  def release_note
    @project = Project.find(params[:id])
    render :text => "Project #{params[:id].inspect} not found", :status => 404 and return unless @project

    @project.generate_release_note(params[:from], params[:to], params[:message], params[:email], params[:release_label] ) rescue nil

    respond_to do |format| 
      format.html do
        if request.xhr?
          render_projects_partial(Project.all)
        else
          redirect_to :controller => "builds", :action => "show", :project => @project
        end
      end
    end
  end

  def kill_build
    @project = Project.find(params[:id])
    @project.kill_build rescue nil

    respond_to do |format|
      format.html do
        if request.xhr?
          render_projects_partial(Project.all)
        else
          redirect_to :action => 'index'
        end
      end
    end
  end

  def kill_all_builders
    killed = []

    @projects = Project.all
    @projects.each do |project|
      unless project.builder_down?
        project.kill_build rescue nil
        killed << project.name
      end
    end
    flash[:notice] = "#{pluralize(killed.count, 'project')} killed: #{killed.join(", ")}"

    respond_to do |format|
      format.html do
        if request.xhr?
          render_projects_partial(Project.all)
        else
          redirect_to :action => 'index'
        end
      end
    end
  end

  def code
    if CruiseControl::Configuration.disable_code_browsing
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


  private

    def render_projects_partial(projects)
      if projects.empty?
        render :partial => 'no_projects'
      else
        render :partial => 'project', :collection => projects
      end
    end

    def project_to_attributes(project)
      { 'name' => project.name }
    end
    
    def disable_add_project
      return unless CruiseControl::Configuration.disable_add_project
      render :text => 'Build requests are not allowed', :status => :forbidden
    end
end
