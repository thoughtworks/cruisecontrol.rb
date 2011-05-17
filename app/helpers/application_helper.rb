# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def human_time(time)
    epoch = Time.at(0)
    today = Time.now.beginning_of_day
    this_year = today.beginning_of_year

    format = if time >= epoch && time < this_year
      "human.before_this_year"
    elsif time >= this_year && time < today
      "human.this_year"
    elsif time >= today && time < ( today + 1.day )
      "human.today"
    else
      "human.future"
    end

    remove_leading_zero I18n.l(time, :format => format.to_sym)
  end

  def format_time(time, format = :iso)
    I18n.l time, :format => format
  end
  
  def format_seconds(total_seconds, format = :general)
    DurationFormatter.new(total_seconds).send(format)
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

  def link_to_build(project, build)
    text = build_label(build)
    if build.failed?
      text += " FAILED"
    elsif build.incomplete?
      text += " incomplete"
    end
    build_link(text, project, build)
  end

  def build_to_text(build, with_elapsed_time = true)
    text = build_label(build)
    if build.failed?
      text += ' FAILED'
    elsif build.incomplete?
      text += ' incomplete'
    else
      elapsed_time_text = elapsed_time(build)
      text += " took #{elapsed_time_text}" if (with_elapsed_time and !elapsed_time_text.empty?)
    end
    return text.html_safe
  end
  
  def link_to_build_with_elapsed_time(project, build)
    build_link(build_to_text(build), project, build)
  end
    
  def display_builder_state(state)
    case state
    when 'building', 'builder_down', 'build_requested', 'source_control_error', 'queued', 'timed_out', 'error'
      content_tag :div, state.gsub('_', ' ').humanize + ".", :class => "builder_status_#{state}"
    when 'sleeping', 'checking_for_modifications'
      ''
    else
      content_tag :div, state.humanize + ".", :class => "builder_status_unknown"
    end
  end

  def format_changeset_log(log)
    h(log.strip)
  end
  
  def elapsed_time(build, format = :general)
    begin
      content_tag :span, format_seconds(build.elapsed_time, format)
    rescue
      '' # The build time is not present.
    end
  end
  
  def build_link(text, project, build)
    link_to text, build_path(:project => project.name, :build => build.label),
            :class => build.status, :title => format_changeset_log(build.changeset)
  end
  
  def url_path(url)
    if url.is_a?(Hash)
      url_for(url.merge(:only_path => true))
    else
      url.match(/\/\/.+?(\/.+)/)[1]
    end
  end

  def button_tag(label, attrs={})
    content_tag :button, label, attrs
  end
        
  private
  
  def build_label(build)
    "#{build.abbreviated_label} (#{human_time(build.time)})"
  end

  def remove_leading_zero(string)
    string.gsub(/^0(\d:\d\d|\d )/, '\1')
  end

end
