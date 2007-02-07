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
test_should_check_force_build(PollingSchedulerTest) [./test/unit/polling_scheduler_test.rb:44]:
#<Mocha::Mock:0x-245ea224>.force_build_if_requested - expected calls: 1, actual calls: 2

125 tests, 284 assertions, 1 failures, 0 errors
/usr/bin/ruby1.8 -Ilib:test "/usr/lib/ruby/1.8/rake/rake_test_loader.rb" "test/functional/projects_controller_test.rb" 
Loaded suite /usr/lib/ruby/1.8/rake/rake_test_loader
Started
..........
Finished in 0.251448 seconds.

10 tests, 23 assertions, 0 failures, 0 errors
/usr/bin/ruby1.8 -Ilib:test "/usr/lib/ruby/1.8/rake/rake_test_loader.rb" "test/integration/builder_integration_test.rb" 
Loaded suite /usr/lib/ruby/1.8/rake/rake_test_loader
Started
..............
Finished in 25.224997 seconds.

14 tests, 28 assertions, 0 failures, 0 errors
rake aborted!
Test failures
EOF
  
  def test_should_not_find_test_errors_with_a_build_with_test_failures
    testErrors = TestErrorParser.new.get_test_errors(LOG_OUTPUT_WITH_TEST_FAILURE)
    assert_equal 0, testErrors.length
  end

  def test_should_find_no_test_errors_with_successful_build
    testErrors = TestErrorParser.new.get_test_errors(LOG_OUTPUT_WITH_NO_TEST_ERRORS)
    assert_equal 0, testErrors.length        
  end  
  
  def test_should_find_test_errors_with_unsuccessful_build
    testErrors = TestErrorParser.new.get_test_errors(LOG_OUTPUT_WITH_TEST_ERRORS)
    assert_equal 1, testErrors.length
    assert_equal expected_test_error.test_name, testErrors[0].test_name
        assert_equal expected_test_error.message, testErrors[0].message
            assert_equal expected_test_error.stacktrace, testErrors[0].stacktrace
  end
  
  
  def expected_test_error
    TestErrorEntry.create_error("test_should_fail_due_to_comparing_same_objects_with_different_data(TestFailureParserTest)",
                                "NameError: undefined local variable or method `expectedFirstTestFixture' for #<TestFailureParserTest:0x3f65a60>",
                                "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/rails/actionpack/lib/action_controller/test_process.rb:456:in `method_missing'\n" +
                                "    ./test/unit/test_failure_parser_test.rb:75:in `test_should_fail_due_to_comparing_same_objects_with_different_data'\n" +
                                "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `__send__'\n" +
                                "    C:/projects/cruisecontrol.rb/builds/ccrb/work/config/../vendor/plugins/mocha/lib/mocha/test_case_adapter.rb:19:in `run'")    
  end
  
end
