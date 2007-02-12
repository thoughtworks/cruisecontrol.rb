require File.dirname(__FILE__) + '/../test_helper'

class ProjectsController
  attr_accessor :url
end

class BuildsHelperTest < Test::Unit::TestCase
  include BuildsHelper
  include ActionView::Helpers::UrlHelper
  
  def setup
    @work_path = '/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work'
    @project = Project.new('mine')
  end
  
  def test_format_build_log_converts_lines
    assert_equal "this is a<br/>\nline<br/>\nbreak", format_build_log("this is a\nline\nbreak")
  end

  def test_format_build_log_makes_test_summaries_bold
    assert_equal "limes <div class=\"test-results\">5 tests, 20 assertions, 10 failures, 2 errors</div> foo",
                 format_build_log("limes 5 tests, 20 assertions, 10 failures, 2 errors foo")
  end

  def test_format_build_log_links_to_code
    expected = <<-EOL
<a href="/projects/code/mine/vendor/rails/activesupport/lib/active_support/dependencies.rb?line=477#477">./vendor/rails/activesupport/lib/active_support/dependencies.rb:477</a>:in `const_missing'<br/>
<a href="/projects/code/mine/test/unit/builder_status_test.rb?line=8#8">./test/unit/builder_status_test.rb:8</a>:in `setup'<br/>
    EOL
    
    log = <<-EOL
/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work/config/../vendor/rails/actionpack/lib/../../activesupport/lib/active_support/dependencies.rb:477:in `const_missing'
./test/unit/builder_status_test.rb:8:in `setup'
    EOL
    
    assert_equal expected, format_build_log(log)
  end

  def test_format_build_log_doesnt_link_to_code_outside_project
    expected = <<-EOL
../foo:20<br/>
<a href="/projects/code/mine/index.html?line=30#30">./index.html:30</a><br/>
/ruby/gems/ruby.rb:25<br/>
    EOL
    
    log = <<-EOL
../foo:20
../work/index.html:30
/ruby/gems/ruby.rb:25
    EOL
    
    assert_equal expected, format_build_log(log)
  end
  
  # this is tested elsewhere in depth, this is a functional test
  def test_parse_test_results
    log = <<-EOL
  1) Error:
test_build_loop_failed_creates_file__build_loop_failed__(BuilderStatusTest):
NameError: uninitialized constant BuilderStatusTest::BuilderStatus
    ./test/unit/builder_status_test.rb:8:in `setup'

  2) Error:
test_build_started_creates_file__building__(BuilderStatusTest):
NameError: uninitialized constant BuilderStatusTest::BuilderStatus
    /active_support/dependencies.rb:477:in `const_missing'
    ./test/unit/builder_status_test.rb:8:in `setup'

    EOL
    
    expected = <<-EOL
Name: test_build_loop_failed_creates_file__build_loop_failed__(BuilderStatusTest)<br/>
Type: Error<br/>
Message: NameError: uninitialized constant BuilderStatusTest::BuilderStatus<br/>
<br/>
<span class=\"error\"> &nbsp; &nbsp;<a href=\"/projects/code/mine/test/unit/builder_status_test.rb?line=8#8\">./test/unit/builder_status_test.rb:8</a>:in `setup'</span><br/>
<br/>
<br/>
Name: test_build_started_creates_file__building__(BuilderStatusTest)<br/>
Type: Error<br/>
Message: NameError: uninitialized constant BuilderStatusTest::BuilderStatus<br/>
<br/>
<span class=\"error\"> &nbsp; &nbsp;/active_support/dependencies.rb:477:in `const_missing'<br/>
 &nbsp; &nbsp;<a href=\"/projects/code/mine/test/unit/builder_status_test.rb?line=8#8\">./test/unit/builder_status_test.rb:8</a>:in `setup'</span><br/>
<br/>
<br/>
    EOL
    
    assert_equal expected, get_test_failures_and_errors_if_any(log)
  end
  
  def h(text)
    text
  end
end
