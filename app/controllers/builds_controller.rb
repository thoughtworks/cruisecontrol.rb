class BuildsController < ApplicationController
  layout 'default'
  caches_page :drop_down
  
  def show
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Projects.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    if params[:build]
      @build = @project.find_build(params[:build])
      render :text => "Build #{params[:build].inspect} not found", :status => 404 and return if @build.nil? 
    else
      @build = @project.last_build
      render :action => 'no_builds_yet' and return if @build.nil?
    end
      
    @autorefresh = @build.incomplete?
  end

  def drop_down
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Projects.find(params[:project])
    render :layout => false
  end
  
  def artifact
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    render :text => 'Build not specified', :status => 404 and return unless params[:build]
    render :text => 'Path not specified', :status => 404 and return unless params[:path]

    @project = Projects.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project
    @build = @project.find_build(params[:build])
    render :text => "Build #{params[:build].inspect} not found", :status => 404 and return unless @build

    path = File.join(@build.artifacts_directory, params[:path])

    if File.directory? path
      if File.exists?(path + '/index.html')
        redirect_to :path => File.join(params[:path], 'index.html')
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
  def get_mime_type(name)
    case name.downcase
    when /\.html$/
      'text/html'
    when /\.js$/
      'text/javascript'
    when /\.css$/
      'text/css'
    when /\.gif$/
      'image/gif'
    when /(\.jpg|\.jpeg)$/
      'image/jpeg'
    when /\.png$/
      'image/png'
    when /\.zip$/
      'application/zip'
    else
      'text/plain'
    end
  end

end