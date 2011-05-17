class BuildsController < ApplicationController
  caches_page :drop_down
  
  def show
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    if params[:build]
      @build = @project.find_build(params[:build])
      render :text => "Build #{params[:build].inspect} not found", :status => 404 and return if @build.nil? 
    else
      @build = @project.last_build
      render :action => 'no_builds_yet' and return if @build.nil?
    end

    @builds_for_navigation_list = @project.builds.reverse[0, 30]

    @autorefresh = @build.incomplete?
  end

  def drop_down
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Project.find(params[:project])
    @builds_for_dropdown = @project.builds.reverse[30..-1]
    render :layout => false
  end
  
  def artifact
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    render :text => 'Build not specified', :status => 404 and return unless params[:build]
    render :text => 'Path not specified', :status => 404 and return unless params[:path]

    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project
    @build = @project.find_build(params[:build])
    render :text => "Build #{params[:build].inspect} not found", :status => 404 and return unless @build

    path = @build.artifact(params[:path])

    if File.directory? path
      if File.exists?(File.join(path, 'index.html'))
        redirect_to request.fullpath + '/index.html'
      else
        # TODO: generate an index from directory contents
        render :text => "this should be an index of #{params[:path]}"
      end
    elsif File.exists? path
      send_file(path, :type => get_mime_type(path), :disposition => 'inline', :stream => false)
    else
      render_not_found
    end
  end
  
  private
  
  MIME_TYPES = {
    "html" => "text/html",
    "js"   => "text/javascript",
    "css"  => "text/css",
    "gif"  => "image/gif",
    "jpg"  => "image/jpeg",
    "jpeg" => "image/jpeg",
    "png"  => "image/png",
    "zip"  => "application/zip"
  }

  def get_mime_type(name)
    extension = name.downcase.split(".").last
    return MIME_TYPES[ extension ]if MIME_TYPES.has_key? extension
    "text/plain"
  end

end