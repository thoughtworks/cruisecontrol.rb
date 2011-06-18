module BuildsHelper

  def file_mtime(path)
    file = @build.artifact(path)
    return if File.symlink?(file)

    mtime = File.mtime(file)
    if (mtime.to_i > Time.now.to_i - 24*60*60)
      mtime.strftime("%I:%M:%S %p")
    else
      mtime.strftime("%d-%m-%Y")
    end
  end
  
  def file_size(path)
    file = @build.artifact(path)
    File.size(file)
  end
  
  def file_type(path)
    file = @build.artifact(path)
    return 'directory' if File.directory?(file)
    Rack::Mime::MIME_TYPES[File.extname(file)] || 'unknown'
  end

  def select_builds(project, builds)
    return "" if builds.blank?

    options = [ [ "Older Builds...", nil ] ] + builds.map do |build|
      [ build_to_text(build, false), build_path(project.id, build.label) ]
    end
    
    select_tag "build", options_for_select(options)
  end
  
  def format_build_log(log)
    strip_ansi_colors(highlight_test_count(link_to_code(h(log))))
  end
  
  def link_to_code(log)
    return log if Configuration.disable_code_browsing
    @work_path ||= File.expand_path(@project.path + '/work')
    
    log.gsub(/(\#\{RAILS_ROOT\}\/)?([\w\.-]*\/[ \w\/\.-]+)\:(\d+)/) do |match|
      path = File.expand_path($2, @work_path)
      line = $3
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to(match, "/projects/code/#{h @project.name}#{path}?line=#{line}##{line}")
      else
        match
      end
    end
  end
  
  def format_project_settings(settings)
    settings = settings.strip
    if settings.empty?
      "This project has no custom configuration. Maybe it doesn't need it.<br/>" +
      "Otherwise, #{link_to('the manual', document_path('manual'))} can tell you how."
    else
      h(settings)
    end
  end
  
  def failures_and_errors_if_any(log)
    BuildLogParser.new(log).failures_and_errors
  end
  
  def format_test_error_output(test_error)
    message = test_error.message

    "Name: #{test_error.test_name}\n" +
    "Type: #{test_error.type}\n" +
    "Message: #{h message}\n\n" +
    "<span class=\"error\">#{h test_error.stacktrace}</span>\n\n\n"
  end

  def display_build_time
    build_time_text = remove_leading_zero I18n.l(@build.time, :format => :verbose)

    if @build.incomplete?
      if @build.latest?
        "building for #{format_seconds(@build.elapsed_time_in_progress, :general)}"
      else
        "started at #{build_time_text}, and never finished"
      end
    else
      elapsed_time_text = elapsed_time(@build, :precise)
      elapsed_time_text.empty? ? "finished at #{build_time_text}" : "finished at #{build_time_text} taking #{elapsed_time_text}".html_safe
    end
  end

  private

  def highlight_test_count(log)
    log.gsub(/\d+ tests, \d+ assertions, \d+ failures, \d+ errors/, '<div class="test-results">\0</div>').
        gsub(/\d+ examples, \d+ failures/, '<div class="test-results">\0</div>')
  end

  def strip_ansi_colors(log)
    log.gsub(/\e\[\d+m/, '')
  end
end