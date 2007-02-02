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

  def format_time(time, format = :iso)
    case format
    when :human
      remove_leading_zeros(
        Time.now > time + 24.hours ?
          time.strftime('at %b %d') :
          time.strftime('on %H:%M'))
    when :iso
      time.strftime('%Y-%m-%d %H:%M:%S')
    when :iso_date
      time.strftime('%Y-%m-%d')
    when :verbose
      remove_leading_zeros(time.strftime('%I:%M %p on %B %d, %Y'))
    else
      raise "Unknown time format #{format.inspect}"
    end
  end
  
  # surely there's a way to do this with strftime, but I couldn't find it... - jss
  def remove_leading_zeros(string)
    string.gsub(/(^| |,)0+/, '\1')
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
