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

  def update
    projects = load_projects
    @project = find_project(projects)

    # we can only have one of rake_task or build_command
    params[:project][:rake_task] = nil if params[:project][:build_command] and !params[:project][:build_command].empty?
    @project.rake_task = @project.build_command = nil
    
    update_attributes(@project, params[:project])
    
    projects.save_project @project
    render :action => 'settings'
  end
  
  def add_email
    projects = load_projects
    @project = find_project(projects)

    @project.emails << params[:value]

    projects.save_project @project
    update_emails
  end

  def remove_email
    projects = load_projects
    @project = find_project(projects)

    @project.emails.delete params[:value]

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
    projects.find {|p| p.url_name == params[:id] }
  end
  
  def update_attributes(obj, hash)
    hash.each do |key, value|
      if value.is_a? Hash
        update_attributes(obj.send(key.to_sym), value)
      else
        if value == ''
          value = nil
        elsif value =~ /^[0-9]+$/
          value = value.to_i
        end
        obj.send("#{key}=", value)
      end
    end
  end
end