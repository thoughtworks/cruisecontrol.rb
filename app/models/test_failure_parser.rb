class TestFailureParser    
  TEST_NAME_REGEX = /\S+/
  MESSAGE_REGEX = /\]\:\n([\s\S]+)/
  STACK_TRACE_REGEX = /\[([\s\S]*?)\]\:/
  TEST_FAILURE_BLOCK_REGEX = /^\s+\d+\) Failure:\n([\S\s]*?)\n\n/
  def get_test_failures(log)
    testFailures = Array.new
    
    log.gsub(TEST_FAILURE_BLOCK_REGEX) do |text|
      content = $1
     
      begin
        test_name = content.match(TEST_NAME_REGEX).to_s      
        message = content.match(MESSAGE_REGEX)[1]
        stack_trace = content.match(STACK_TRACE_REGEX)[1]
      rescue
        # Do Nothing, Pattern does not match
      end
      
      testFailures << TestErrorEntry.create_failure(test_name, message, stack_trace)
    end
    
    testFailures
  end
end