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
  
  def server_settings_page_breadcrumb
    dashboard_breadcrumb
    add_breadcrumb 'Server Settings', :controller => 'admin', :action => 'server_settings'
  end
  
  def email_settings_page_breadcrumb
    server_settings_page_breadcrumb
    add_breadcrumb 'E-Mail Settings', :controller => 'admin', :action => 'email_settings'
  end
  
  def project_page_breadcrumb
    dashboard_breadcrumb
    add_breadcrumb @project.name, :controller => 'project', :action => 'show', :id => @project.url_name
  end
  
  def project_settings_page_breadcrumb
    project_page_breadcrumb
    add_breadcrumb 'Settings', :controller => 'project', :action => 'settings', :id => @project.url_name
  end
  
  def color_for_status(build)
    build.successful? ? 'green' : 'red'
  end
  
  def setting_row(label, value, help = '&nbsp;')
    <<-EOL
    <tr>
      <td class='label'>#{label} :</td>
      <td>#{value}</td>
      <td class='help'>#{help}</td>
    </tr>
    EOL
  end
end
