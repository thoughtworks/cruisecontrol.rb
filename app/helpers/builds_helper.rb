module BuildsHelper

  def builds_except_last(project, n)
    project.builds.reverse[n..-1]
  end
  
  def select_builds(builds)
    return "" if !builds || builds.empty?

    options = builds.map do |build|
      "<option value='#{build.label}'>#{text_to_build(build, false)}</option>"
    end
    options.unshift "<option value=''>Older Builds...</option>"
    
    select_tag "build", options, :onChange => "this.form.submit();"
  end
  
  def format_build_log(log)
    link_to_code(h(log).gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/,
                             '<div class="test-results">\1</div>'))
  end
  
  def link_to_code(log)
    @work_path ||= File.expand_path(@project.path + '/work')
    
    log.gsub(/(\#\{RAILS_ROOT\}\/)?([\w\.-]*\/[ \w\/\.-]+)\:(\d+)/) do |match|
      path = File.expand_path($2, @work_path)
      line = $3
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to match, "/projects/code/#{h @project.name}#{path}?line=#{line}##{line}"
      else
        match
      end
    end
  end
  
  def format_project_settings(settings)
    settings = settings.strip
    if settings.empty?
      "This project has no custom configuration. Maybe it doesn't need it.<br/>" +
      "Otherwise, #{link_to('the manual', document_url('manual'))} can tell you how."
    else
      h(settings)
    end
  end
  
  def failures_and_errors_if_any(log)
    errors = LogParser.new(log).failures_and_errors
    return nil if errors.empty?
    
    link_to_code(errors.collect{|error| format_test_error_output(error)}.join)
  end
  
  def format_test_error_output(test_error)
    message = test_error.message.gsub(/\\n/, "\n");
    
    "Name: #{test_error.test_name}\n" +
    "Type: #{test_error.type}\n" +
    "Message: #{h message}\n\n" +
    "<span class=\"error\">#{h test_error.stacktrace}</span>\n\n\n"
  end
  
  def display_build_time
    if @build.incomplete?
      "building for #{format_seconds(@build.elapsed_time_in_progress, :general)}"
    else
      elapsed_time_text = elapsed_time(@build, :precise)
      build_time_text = format_time(@build.time, :verbose)
      elapsed_time_text.empty? ? "finished at #{build_time_text}" : "finished at #{build_time_text} taking #{elapsed_time_text}"
    end
  end
end