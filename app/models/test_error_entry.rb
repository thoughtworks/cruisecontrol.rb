TestErrorEntry = Struct.new :type, :test_name, :message, :stacktrace

class TestErrorEntry
  ERROR_TYPE = "Error"
  FAILURE_TYPE = "Failure"

  def self.create_failure(test_name, message, stacktrace)
    TestErrorEntry.new(FAILURE_TYPE, test_name, message, stacktrace)
  end

  def self.create_error(test_name, message, stacktrace)
    TestErrorEntry.new(ERROR_TYPE, test_name, message, stacktrace)
  end

end