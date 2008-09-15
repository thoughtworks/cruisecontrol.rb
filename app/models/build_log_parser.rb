class BuildLogParser

  TEST_ERROR_REGEX = /^\s+\d+\) Error:\n(.*):\n(.*)\n([\s\S]*?)\n\n/
  TEST_FAILURE_REGEX = /^\s+\d+\) Failure:\n([\S\s]*?)\n\n/

  RSPEC_ERROR_REGEX = /^\s\d+\)\n(\S+) in '(.*)'\n((.+\n)+)\n/ 
  RSPEC_FAILURE_REGEX = /^\s+\d+\)\n'(.*)' FAILED\n((.+\n)+)\n/
  RSPEC_STACK_TRACE_REGEX = /^.*:\d+:.*$/
  
  TEST_NAME_REGEX = /\S+/
  MESSAGE_REGEX = /\]\:\n([\s\S]+)/
  STACK_TRACE_REGEX = /\[([\s\S]*?)\]\:/

  def initialize(log)
    @log = log
  end

  def errors
    test_errors + rspec_errors
  end

  def test_errors
    test_errors = []
    
    @log.scan(TEST_ERROR_REGEX) do |match|
      test_errors << TestErrorEntry.create_error($1, $2, $3)
    end
  
    return test_errors
  end

  def rspec_errors
    rspec_errors = []

    @log.scan(RSPEC_ERROR_REGEX) do |match|
      exception_name = $1
      spec_name = $2
      content = $3.chomp

#      stack_trace_pos = (content =~ RSPEC_STACK_TRACE_REGEX)

#      rest_of_the_message = content[0...stack_trace_pos].chomp
#      message = "#{exception_name} in '#{spec_name}'\n#{rest_of_the_message}"
      message = "#{exception_name} in '#{spec_name}'\n#{content}"
#      stack_trace = content[stack_trace_pos..-1]

#      rspec_errors << TestErrorEntry.create_error(spec_name, message, stack_trace)
      rspec_errors << TestErrorEntry.create_error(spec_name, message, [])
    end
    
    return rspec_errors
  end

  def failures
    test_failures + rspec_failures
  end
  
  def test_failures
    test_failures = []

    @log.scan(TEST_FAILURE_REGEX) do |text|
      content = $1

      begin
        test_name = content.match(TEST_NAME_REGEX).to_s
        message = content.match(MESSAGE_REGEX)[1]
        stack_trace = content.match(STACK_TRACE_REGEX)[1]

        test_failures << TestErrorEntry.create_failure(test_name, message, stack_trace)
      rescue
        # Do Nothing, Pattern does not match
      end
    end

    test_failures
  end

  def rspec_failures
    rspec_failures = []

    @log.scan(RSPEC_FAILURE_REGEX) do |text|
      spec_name = $1
      content = $2.chomp

      stack_trace_pos = (content =~ RSPEC_STACK_TRACE_REGEX)
      message = content[0...stack_trace_pos].chomp
      stack_trace = content[stack_trace_pos..-1]

      rspec_failures << TestErrorEntry.create_failure(spec_name, message, stack_trace)
    end

    rspec_failures
  end

  def failures_and_errors
    failures + errors
  end

end
