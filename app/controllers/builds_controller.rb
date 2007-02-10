class BuildsController < ApplicationController
  layout 'default'
  
  def show
    @project = find_project(load_projects)

    if params.has_key? :build
      @build = @project.find_build(params[:build])
    end
    @build ||= @project.last_build
    
    render :action => 'no_builds_yet' unless @build
  end
  
  def artifact
    @project = find_project(load_projects)
    @build = @project.find_build(params[:build])

    path = File.join(@build.artifacts_directory, params[:artifact_path])
    
    if params[:artifact_path].index '..'
      render :nothing => true, :status => 401 
    elsif File.directory? path
      if File.exists? path + "/index.html"
        redirect_to :artifact_path => File.join(params[:artifact_path], 'index.html')
      else
        # eventually spit up an index
        render :text => "this should be an index of #{params[:artifacts_path]}"
      end
    elsif File.exists? path
      send_file(path, :type => get_mime_type(path), :disposition => 'inline', :stream => false)
    else
      render :nothing => true, :status => 404
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
    else
      'text/plain'
    end
  end
end