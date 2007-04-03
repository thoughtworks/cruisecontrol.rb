class BuildsController < ApplicationController
  layout 'default'
  caches_page :drop_down
  
  def show
    err = load_project_and_build
    render :text => err[0], :status => err[1] and return if err
    render :action => (@build ? 'show' : 'no_builds_yet')
  end

  def drop_down
    err = load_project_and_build
    render :text => err[0], :status => err[1] and return if err
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
  def load_project_and_build
    return ['Project not specified', 404] unless params[:project]
    @project = Projects.find(params[:project])
    return ["Project #{params[:project].inspect} not found", 404] unless @project
    @build = (params[:build] ? @project.find_build(params[:build]) : @project.last_build)
    return nil
  end
  
  
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
    else
      'text/plain'
    end
  end

end