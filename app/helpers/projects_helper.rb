def format_changeset_log(log)
  log.strip
end

def link_to_build(project, build)
  text = "#{build.label} (#{format_time(build.time, :human)})"
  text += " <span class='error'>FAILED</span>" if build.failed?
  link_to text, {:action => 'show', :id => project.name, :build => build.label}, :class => build.status
end

def format_build_log(log)
  convert_new_lines(log.gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>'))
end

def display_test_failures_and_errors_if_any(log)
  output = String.new
  
  testFailures = TestFailureParser.new.get_test_failures(log)
  testFailures.each {|testFailure| output << format_test_error_output(testFailure)}
    
  testErrors = TestErrorParser.new.get_test_errors(log)
  testErrors.each {|testError| output << format_test_error_output(testError)}
    
  if output != String.new
    output.strip
  else
    "None"
  end
end

def format_test_error_output(testError)
  message = testError.message.gsub(/\\n/, "\n");

  "Name: #{testError.test_name}\n" +
  "Type: #{testError.type}\n" +
  "Message: #{message}\n\n" +
  "<span class=\"error\">#{testError.stacktrace}</span>\n\n\n"
end

def convert_new_lines(value)
  value.gsub(/\n/, "<br/>\n")
end