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
  
  def format_seconds(total_seconds, format = :general)
    minutes, seconds = total_seconds.divmod(60)
    hours, minutes = minutes.divmod(60)
    
    hours == 1 ? hours_label = "hour" : hours_label = "hours"
    seconds == 1 ? seconds_label = "second" : seconds_label = "seconds"
    minutes == 1 ? minutes_label = "minute" : minutes_label = "minutes"
    
    case format    
    when :general
      return "#{hours} #{hours_label}" if hours >= 1 and minutes == 0
      return "#{hours} #{hours_label} #{minutes} #{minutes_label}" if hours >= 1      
      return "#{minutes} #{minutes_label}" if minutes >= 1
      return "#{seconds} #{seconds_label}"
    when :precise
      result = []
      result << "#{hours} #{hours_label}" unless hours == 0
      result << "#{minutes} #{minutes_label}" unless minutes == 0
      result << "#{seconds} #{seconds_label}" unless seconds == 0 and total_seconds != 0
      result.join(" and ")
    else
      raise "Unknown seconds format #{format.inspect}"
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
    if build.failed?
      text += " <span class='error'>FAILED</span>"
    else
      elapsed_time_text = elapsed_time(build)
      text += " took #{elapsed_time_text}" unless elapsed_time_text.empty?
    end
    link_to_build(text, project, build)
  end
    
  def display_builder_state(state)
    case state
    when 'building', 'builder_down', 'build_requested'
      "<div class=\"builder_status_#{state}\">#{state.gsub('_', ' ')}</div>"
    when 'sleeping', 'checking_for_modifications'
      ''
    else
      "<div class=\"builder_status_unknown\">#{h state}<br/>unknown state</div>"
    end
  end

  def format_changeset_log(log)
    preify(h(log.strip))
  end
  
  def preify(value)
    value.gsub(/\n/, "<br/>\n").
          gsub(/  /, " &nbsp;").
          gsub(/\S{80}/) { |match| "#{match}&#8203;" }
  end

  def elapsed_time(build, format = :general)
    begin
      "<span>#{format_seconds(build.elapsed_time, format)}</span>"
    rescue
      '' # The build time is not present.
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
