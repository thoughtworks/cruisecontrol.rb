class LogParser
  FIND_TEST_ERROR_REGEX = /^\s+\d+\) Error:\n(.*):\n(.*)\n([\s\S]*?)\n\n/
  TEST_NAME_REGEX = /\S+/
  MESSAGE_REGEX = /\]\:\n([\s\S]+)/
  STACK_TRACE_REGEX = /\[([\s\S]*?)\]\:/
  TEST_FAILURE_BLOCK_REGEX = /^\s+\d+\) Failure:\n([\S\s]*?)\n\n/

  def initialize(log)
    @log = log
  end
  
  def errors
    test_errors = Array.new
    
    @log.gsub(FIND_TEST_ERROR_REGEX) do |match|
      test_errors << TestErrorEntry.create_error($1, $2, $3)
    end    
  
    return test_errors
  end

  def failures
    testFailures = Array.new

    @log.gsub(TEST_FAILURE_BLOCK_REGEX) do |text|
      content = $1

      begin
        test_name = content.match(TEST_NAME_REGEX).to_s
        message = content.match(MESSAGE_REGEX)[1]
        stack_trace = content.match(STACK_TRACE_REGEX)[1]

        testFailures << TestErrorEntry.create_failure(test_name, message, stack_trace)
      rescue
        # Do Nothing, Pattern does not match
      end
    end

    testFailures
  end

  def failures_and_errors
      failures + errors
  end

end
