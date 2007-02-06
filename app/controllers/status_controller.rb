class StatusController < ApplicationController
  # TODO: Investigate whether generation of XML 
  # of projects can be done in controller to allow testing
  def projects
    @url = url_for(:controller => 'projects', :action => 'index')
    @projects = Projects.load_all
  end
end