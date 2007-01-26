require File.dirname(__FILE__) + '/../test_helper'
require 'test_failure_parser'
require 'test_failure_entry'

class TestFailureParserTest < Test::Unit::TestCase

LOG_OUTPUT_WITH_NO_TEST_FAILURE = <<EOF
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

LOG_OUTPUT_WITH_TEST_FAILURE = <<EOF
Loaded suite c:/ruby/lib/ruby/gems/1.8/gems/rake-0.7.1/lib/rake/rake_test_loader
Started
....................................................................FF.............
Finished in 1.453 seconds.

  1) Failure:
test_should_fail(SubversionLogParserTest)
    [./test/unit/subversion_log_parser_test.rb:125:in `test_should_fail'
     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'
     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run']:
<1> expected but was
<"abc">.

  2) Failure:
test_should_fail_two(SubversionLogParserTest)
    [./test/unit/subversion_log_parser_test.rb:129:in `test_should_fail_two'
     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'
     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run']:
<1> expected but was
<"abc">.

83 tests, 185 assertions, 2 failures, 0 errors
EOF



  def test_should_find_no_test_failures_with_successful_build
    testFailures = TestFailureParser.new.get_test_failures(LOG_OUTPUT_WITH_NO_TEST_FAILURE)
    assert_equal 0, testFailures.length        
  end
  
  def test_should_find_test_failures
    testFailures = TestFailureParser.new.get_test_failures(LOG_OUTPUT_WITH_TEST_FAILURE)
    assert_equal 2, testFailures.length
    assert_equal expectedFirstTestFailure, testFailures[0]
    assert_equal expectedSecondTestFailure, testFailures[1]
  end
    
  def test_should_fail_due_to_comparing_different_numbers
    assert_equal 1, 2
  end
    
  def test_should_fail_due_to_comparing_different_objects
    assert_equal String.new, expectedFirstTestFailure
  end
    
  def test_should_fail_due_to_comparing_same_objects_with_different_data
    assert_equal expectedFirstTestFixture, expectedSecondTestFixture
  end
    
  def expectedFirstTestFailure
    TestFailureEntry.new("<1> expected but was\n<\"abc\">.",
                         "./test/unit/subversion_log_parser_test.rb:125:in `test_should_fail'\n" +
                         "     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'\n" +
                         "     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run'")
  end
    
  def expectedSecondTestFailure
    TestFailureEntry.new("<1> expected but was\n<\"abc\">.",
                         "./test/unit/subversion_log_parser_test.rb:129:in `test_should_fail_two'\n" +
                         "     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'\n" +
                         "     C:/projects/cruisecontrol.rb/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run'")
  end
  
end