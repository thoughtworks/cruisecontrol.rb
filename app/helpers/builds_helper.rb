module BuildsHelper


  def format_build_log(log)
    preify(
      link_to_code(h(log).
        gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>')))
  end
  
  def link_to_code(log)
    @work_path ||= File.expand_path(@project.path + '/work')

    log.gsub(/(([\w\.-]*\/[ \w\/\.-]+)\:(\d+))/) { 
      path = File.expand_path($2, @work_path)
      if path.index(@work_path) == 0
        path = path[@work_path.size..-1]
        link_to ".#{path}:#{$3}", "/projects/code/#{@project.name}#{path}?line=#{$3}##{$3}"
      else
        $1
      end
    }
  end

  def get_test_failures_and_errors_if_any(log)
    errors = TestFailureParser.new.get_test_failures(log) + TestErrorParser.new.get_test_errors(log)
    return nil if errors.empty?
    
    preify(link_to_code(errors.collect{|error| format_test_error_output(error)}.join))
  end

  def format_test_error_output(testError)
    message = testError.message.gsub(/\\n/, "\n");

    "Name: #{testError.test_name}\n" +
    "Type: #{testError.type}\n" +
    "Message: #{h message}\n\n" +
    "<span class=\"error\">#{h testError.stacktrace}</span>\n\n\n"
  end
  
  def show_elapsed_time(build)
    begin
      "Total #{format_seconds(build.elapsed_time, :precise)}."
    rescue
      '' # The build time is not present.
    end
  end
  

end