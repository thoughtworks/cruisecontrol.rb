class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    flash[:notice] = nil
    @projects = load_projects
    @build_states = get_build_states(@projects)
  end

  def show
    @project = find_project(load_projects)

    if params.has_key? :build
      @build = @project.builds.find { |build| build.label.to_s == params[:build] }
    end
    @build ||= @project.last_build
    
    render :action => 'no_builds_yet' unless @build
  end

  def refresh_projects
    current_projects = load_projects
    changed_projects = []
    deleted_projects = []
    @build_states = get_build_states(current_projects)
    params[:build_states].split(';').each do |build_state|
      project = current_projects.find {|proj| proj.name == build_state.split(':')[0] }
      if(!project.nil?)
        if (project.builder_and_build_states_tag != build_state.split(':')[1])
          changed_projects << project          
        end
        current_projects.delete(project)
      else
        deleted_projects << build_state.split(':')[0]
      end
    end     
    @projects = changed_projects
    @new_projects = current_projects
    @deleted_projects = deleted_projects
  end
  
  def force_build
    project = find_project(load_projects)
    flash[:projects_flash] = project.request_force_build()      
    redirect_to :action => :index
  end
  
  private

  def load_projects
    Projects.load_all
  end

  def find_project(projects)
    projects.find {|p| p.url_name == params[:id] }
  end

  def get_build_states(projects)
    states = ""
    projects.each do |project|
      states += project.name + ":" + project.builder_and_build_states_tag + ";"
    end
    states
  end

end