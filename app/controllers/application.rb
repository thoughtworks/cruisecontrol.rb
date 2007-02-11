# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_ci_session_id'

  private

  # FIXME none of this data access stuff belongs in the controller
  def load_projects
    Projects.load_all
  end

  def find_project(projects)
    projects.find {|p| p.name == params[:project] }
  end

end
