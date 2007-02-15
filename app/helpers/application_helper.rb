# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_time(time, format = :iso)
    case format
    when :human
      now = Time.now
      this_year = now.beginning_of_year
      today = now.beginning_of_day
      tomorrow = 1.day.since(today)

      format =
        case(time)
        when Time.at(0)...this_year then '%d %b %y'
        when this_year...today then '%d %b'
        when today...tomorrow then '%H:%M'
        else '%Y-%m-%d %H:%M:%S ?future?'
        end
      remove_leading_zero(time.strftime(format))

    when :iso
      time.strftime('%Y-%m-%d %H:%M:%S')
    when :iso_date
      time.strftime('%Y-%m-%d')
    when :verbose
      remove_leading_zero(time.strftime('%I:%M %p on %d %B %Y'))
    when :round_trip_local
      time.strftime('%Y-%m-%dT%H:%M:%S.0000000-00:00') # yyyy'-'MM'-'dd'T'HH':'mm':'ss.fffffffK)
    when :rss
      time.getgm.strftime('%a, %d %b %Y %H:%M:%S Z')
    else
      raise "Unknown time format #{format.inspect}"
    end
  end
  
  # surely there's a way to do this with strftime, but I couldn't find it... - jss
  def remove_leading_zero(string)
    string.gsub(/^0(\d:\d\d|\d )/, '\1')
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

  def link_to_documentation(text = 'Documentation')
    link_to text, '/documentation'
  end
  
  def hyperlink_to_build(project, build)
    text = build_label(build)
    text += " <span class='error'>FAILED</span>" if build.failed?
    link_to_build(text, project, build)
  end

  def hyperlink_to_build_with_elapsed_time(project, build)
    text = build_label(build)
    build.failed? ? text += " <span class='error'>FAILED</span>" : text += " took <span>#{build.elapsed_time}s</span>"          
    link_to_build(text, project, build)
  end
  
  def display_builder_state(state)
    case state
    when 'building', 'builder_down'
      "<div class=\"builder_status_#{state}\">#{state.gsub('_', ' ')}</div>"
    when 'sleeping', 'checking_for_modifications'
      ''
    else
      "<div class=\"builder_status_unknown\">#{h state}<br/>unknown state</div>"
    end
  end

  private
  
  def build_label(build)
    "#{build.label} (#{format_time(build.time, :human)})"
  end
  
  def link_to_build(text, project, build)
    link_to text, build_url(:project => project.name, :build => build.label), :class => build.status
  end
end
