module BuildsHelper
  
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
  
  def get_test_failures_and_errors_if_any(log)
    errors = TestFailureParser.new.get_test_failures(log) + TestErrorParser.new.get_test_errors(log)
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
    elapsed_time_text = elapsed_time(@build, :precise)
    build_time_text = format_time(@build.time, :verbose)
    elapsed_time_text.empty? ? "finished at #{build_time_text}" : "finished at #{build_time_text} taking #{elapsed_time_text}"
  end
  
  def navigate_build_link(text, project, build = nil)
    if build.nil?
      link_to text, url_for(:project => project.name), :class => 'navigate_build'
    else
      link_to text, url_for(:project => project.name, :build => build.label), :class => 'navigate_build'
    end
  end
  
end