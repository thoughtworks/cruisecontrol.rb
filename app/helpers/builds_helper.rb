module BuildsHelper


  def format_build_log(log)
    preify(
      link_to_code(h(log).
        gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>')))
  end
  
  def link_to_code(log)
    @work_path ||= File.expand_path(@project.path + '/work')

    log.gsub(/(([\w\.-]*\/[ \w\/\.-]+)\:(\d+))/) do
      path = File.expand_path($2, @work_path)
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to ".#{path}:#{$3}", "/projects/code/#{@project.name}#{path}?line=#{$3}##{$3}"
      else
        $1
      end
    end
  end

  def get_test_failures_and_errors_if_any(log)
    errors = TestFailureParser.new.get_test_failures(log) + TestErrorParser.new.get_test_errors(log)
    return nil if errors.empty?
    
    preify(link_to_code(errors.collect{|error| format_test_error_output(error)}.join))
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
end