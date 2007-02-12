class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    @projects = Projects.load_all
  end

  def refresh_projects
    @projects = Projects.load_all
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
    
    if params[:path].index '..'
      render :nothing => true, :status => 401
    elsif File.directory?(path)
      render :text => 'directories are not yet supported'
    elsif File.exists?(path)
      @content = File.read(path)
    else
      render :text => "#{path} not found", :status => 404
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