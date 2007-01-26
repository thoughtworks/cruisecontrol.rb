# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def add_breadcrumb(name, link)
    if @breadcrumbs
      @breadcrumbs << " > "
    else
      @breadcrumbs = ""
    end
    
    @breadcrumbs << link_to(name, link)
  end
  
  def dashboard_breadcrumb
    add_breadcrumb 'Dashboard', '/'
  end
  
  def project_page_breadcrumb
    dashboard_breadcrumb
    add_breadcrumb @project.name, :action => 'show', :id => @project.url_name
  end
  
  def project_settings_page_breadcrumb
    project_page_breadcrumb
    add_breadcrumb 'Settings', :action => 'settings', :id => @project.url_name
  end
  
  def color_for_status(build)
    build.successful? ? 'green' : 'red'
  end
end
