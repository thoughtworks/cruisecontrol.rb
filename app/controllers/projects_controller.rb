class ProjectsController < ApplicationController
  layout 'default'
  
  def index
    flash[:notice] = nil
    @projects = load_projects
    @build_states = get_build_states(@projects)
  end

  def refresh_projects
    current_projects = load_projects
    changed_projects = []
    deleted_projects = []
    @build_states = get_build_states(current_projects)
    original_build_states = (params[:build_states] or '')
    original_build_states.split(';').each do |build_state|
      project_name, original_state = build_state.split(':')
      project = current_projects.find { |proj| proj.name == project_name }
      if project
        changed_projects << project if project.builder_and_build_states_tag != original_state
        current_projects.delete(project)
      else
        deleted_projects << project_name
      end
    end
    @projects = changed_projects
    @new_projects = current_projects
    @deleted_projects = deleted_projects
  end
  
  def force_build
    project = find_project(load_projects)
    flash[:projects_flash] = project.request_force_build      
    redirect_to :action => :index
  end
  
  private

  def get_build_states(projects)
    states = ''
    projects.each do |project|
      states += project.name + ":" + project.builder_and_build_states_tag + ";"
    end
    states
  end
end