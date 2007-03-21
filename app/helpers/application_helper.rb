# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_time(time, format = :iso)
    TimeFormatter.send(format, time)
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
    text += " <span class='error'>FAILED</span>" if build.failed?
    build_link(text, project, build)
  end
  
  def select_builds_except_last(project, n)
    all_builds = project.builds.reverse
    all_builds = all_builds - all_builds[0..(n-1)]
    options = ["<option value='' selected='selected'>Older Builds...</option>"]
    options = options + all_builds.map do |build|
      "<option value='#{build.label}' #{selected build}>#{text_to_build(build)}</option>"
    end
    select_tag "build", options, :onChange => "this.form.submit();"
  end
  
  def selected(build)
    build.label == @build.label ? "selected = 'selected'" : "" 
  end

  def text_to_build(build)
    text = build_label(build)
    if build.failed?
      text += ' FAILED'
    elsif build.incomplete?
      text += ' incomplete'
    else
      elapsed_time_text = elapsed_time(build)
      text += " took #{elapsed_time_text}" unless elapsed_time_text.empty?
    end
    return text
  end

  def link_to_build_with_elapsed_time(project, build)
    build_link(text_to_build(build), project, build)
  end
    
  def display_builder_state(state)
    case state
    when 'building', 'builder_down', 'build_requested', 'svn_error'
      "<div class=\"builder_status_#{state}\">#{state.gsub('_', ' ')}</div>"
    when 'sleeping', 'checking_for_modifications'
      ''
    else
      "<div class=\"builder_status_unknown\">#{h state}<br/>unknown state</div>"
    end
  end

  def format_changeset_log(log)
    h(log.strip)
  end
  
  def elapsed_time(build, format = :general)
    begin
      "<span>#{format_seconds(build.elapsed_time, format)}</span>"
    rescue
      '' # The build time is not present.
    end
  end
  
  def build_link(text, project, build)
    link_to text, build_url(:project => project.name, :build => build.label), :class => build.status
  end
        
  private 
  def build_label(build)
    "#{build.label} (#{format_time(build.time, :human)})"
  end    
end
