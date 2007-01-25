class ProjectsController < ApplicationController
  layout "default"
  
  def index
    @projects = load_projects
  end

  def show
    @project = find_project(load_projects)

    if params.has_key? :build
      @build = @project.builds.find {|build| build.label.to_s == params[:build]}
    end

    if !@build
      @build = @project.last_build
    end
  end

  def settings
    @project = find_project(load_projects)
  end

  def add_email
    projects = load_projects
    @project = find_project(projects)

    @project.add_email(params[:value])

    projects.save_project(@project)
    update_emails
  end

  def remove_email
    projects = load_projects
    @project = find_project(projects)

    @project.delete_email(params[:value])

    projects.save_project(@project)
    update_emails
  end

  private

  def update_emails
    render :update do |page|
      page.replace_html "email_list", :partial => 'list'
    end
  end
  
  def load_projects
    Projects.load_all
  end

  def find_project(projects)
    projects.find {|p| p.name == params[:id] }
  end
end