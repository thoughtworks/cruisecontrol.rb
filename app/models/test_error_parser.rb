class TestErrorParser
  TYPE = "Error"
  FIND_TEST_ERROR_REGEX = /^\s+\d+\).*\n(.*):\n(.*)\n([\s\S]*?)\n\n/
  def get_test_errors(log)
    test_errors = Array.new
    
    log.gsub(FIND_TEST_ERROR_REGEX) do |match|
      test_errors << TestErrorEntry.new(TYPE, $1, $2, $3)
    end    
  
    return test_errors
  end
end
