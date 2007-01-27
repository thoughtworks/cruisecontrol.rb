def format_changeset_log(log)
  log.strip
end

def format_build_log(log)
  convert_new_lines(log.gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>'))
end

def display_test_failures_if_any(log)
  output = String.new

  testFailures = TestFailureParser.new.get_test_failures(log)
  testFailures.each {|testFailure| output << format_test_failure_output(testFailure)} 

  if output != String.new
    output.strip
  else
    "None"
  end
end

def format_test_failure_output(testFailure)
  "Message: " + testFailure.message.gsub(/\\n/, "\n") + "\n\n" +
  "<span class=\"error\">#{testFailure.stacktrace}</span>\n\n\n"
end

def convert_new_lines(value)
  value.gsub(/\n/, "<br/>\n")
end