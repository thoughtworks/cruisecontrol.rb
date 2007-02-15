class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    @projects = Projects.load_all

    respond_to do |format|
      format.html
      format.js
      format.rss { render :action => 'rss', :layout => false }
    end
  end

  def force_build   
    @project = nil
    begin       
      @project = Projects.find(params[:project])
      @project.request_force_build
    rescue 
      @project = nil
    end
    @project
 end
  
  def code
    @project = Projects.find(params[:project])
    
    path = File.join(@project.path, 'work', params[:path])
    @line = params[:line].to_i if params[:line]
    
    if File.directory?(path)
      render :text => 'directories are not yet supported'
    elsif File.exists?(path)
      @content = File.read(path)
    else
      render_not_found
    end
  end
  
  private
  
  def serialize_states(projects)
    projects.collect { |project| "#{project.name}:#{project.builder_and_build_states_tag}" }.join(';')
  end

  def deserialize_states(states_string)
    states_string.split(';').collect { |build_state| build_state.split(':') }
  end

end