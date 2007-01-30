require File.dirname(__FILE__) + '/../test_helper'
require 'test_error_parser'
require 'test_error_entry'

class TestErrorParserTest < Test::Unit::TestCase
  
LOG_OUTPUT_WITH_NO_TEST_ERRORS = <<EOF
Started
..................................................................................
Finished in 0.687 seconds.

82 tests, 183 assertions, 0 failures, 0 errors
Loaded suite c:/ruby/lib/ruby/gems/1.8/gems/rake-0.7.1/lib/rake/rake_test_loader
Started
.......
Finished in 0.203 seconds.

7 tests, 13 assertions, 0 failures, 0 errors
Loaded suite c:/ruby/lib/ruby/gems/1.8/gems/rake-0.7.1/lib/rake/rake_test_loader
Started
..........
Finished in 15.689 seconds.

10 tests, 20 assertions, 0 failures, 0 errors
EOF

LOG_OUTPUT_WITH_TEST_ERRORS = <<EOF
Loaded suite c:/ruby/lib/ruby/gems/1.8/gems/rake-0.7.1/lib/rake/rake_test_loader
Started
....................................................................FF.............
Finished in 1.453 seconds.

  3) Error:
test_should_fail_due_to_comparing_same_objects_with_different_data(TestFailureParserTest):
NameError: undefined local variable or method `expectedFirstTestFixture' for #<TestFailureParserTest:0x3f65a60>
    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/rails/actionpack/lib/action_controller/test_process.rb:456:in `method_missing'
    ./test/unit/test_failure_parser_test.rb:75:in `test_should_fail_due_to_comparing_same_objects_with_different_data'
    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'
    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run'

83 tests, 185 assertions, 2 failures, 0 errors
EOF
  
  def test_should_find_no_test_errors_with_successful_build
    testErrors = TestErrorParser.new.get_test_errors(LOG_OUTPUT_WITH_NO_TEST_ERRORS)
    assert_equal 0, testErrors.length        
  end  
  
  def test_should_find_test_errors_with_unsuccessful_build
    testErrors = TestErrorParser.new.get_test_errors(LOG_OUTPUT_WITH_TEST_ERRORS)
    assert_equal 1, testErrors.length
  end
  
  def expected_test_error
    TestErrorEntry.new("test_should_fail_due_to_comparing_same_objects_with_different_data(TestFailureParserTest)",
                       "NameError: undefined local variable or method `expectedFirstTestFixture' for #<TestFailureParserTest:0x3f65a60>",
                       "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/rails/actionpack/lib/action_controller/test_process.rb:456:in `method_missing'\n" +
                       "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'\n" +
                       "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run'")    
  end
  
end
