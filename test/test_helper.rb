ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require_dependency 'application'

# Make double-sure the RAILS_ENV is set to test,
# so fixtures are loaded to the right database
silence_warnings { RAILS_ENV = "test" }

require 'test/unit'
require 'action_controller/test_process'
require 'action_controller/integration'
require 'action_web_service/test_invoke'
require 'breakpoint'
require 'mocha'
require 'stubba'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true

class Test::Unit::TestCase

  def assert_raises(arg1 = nil, arg2 = nil)
    expected_class = arg1.is_a?(Class) ? arg1 : nil
    expected_message = arg1.is_a?(String) ? arg1 : arg2
    begin 
      yield
      fail "expected error was not raised"
    rescue Test::Unit::AssertionFailedError
      raise
    rescue => e
      raise if e.message == "expected error was not raised"
      assert_equal(expected_class, e.class, "Unexpected error type raised") if expected_class
      assert_equal(expected_message, e.message, "Unexpected error message") if expected_message.is_a? String
      assert_matched(expected_message, e.message, "Unexpected error message") if expected_message.is_a? Regexp
    end
  end

end
