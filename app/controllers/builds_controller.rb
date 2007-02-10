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
    
    # if (params[:artifacts_path] =)
    
    name = File.join *[@build.artifacts_directory, params[:artifact_path]].flatten

    send_file(name, :type => get_mime_type(name), :disposition => 'inline', :stream => false)
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