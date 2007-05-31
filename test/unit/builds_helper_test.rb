require File.dirname(__FILE__) + '/../test_helper'

class ProjectsController
  attr_accessor :url
end

class BuildsHelperTest < Test::Unit::TestCase
  include FileSandbox
  include BuildsHelper
  include ApplicationHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  
  def setup
    @work_path = File.expand_path('/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work')
    @project = Project.new('mine')
  end
  
  def test_format_build_log_makes_test_summaries_bold
    assert_equal "limes <div class=\"test-results\">5 tests, 20 assertions, 10 failures, 2 errors</div> foo",
                 format_build_log("limes 5 tests, 20 assertions, 10 failures, 2 errors foo")
  end

  def test_format_build_log_links_to_code_inside_project
    expected = <<-EOL
<a href="/projects/code/mine/vendor/rails/activesupport/lib/active_support/dependencies.rb?line=477#477">/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work/config/../vendor/rails/actionpack/lib/../../activesupport/lib/active_support/dependencies.rb:477</a>:in `const_missing'
<a href="/projects/code/mine/test/unit/builder_status_test.rb?line=8#8">./test/unit/builder_status_test.rb:8</a>:in `setup'
    EOL
    
    log = <<-EOL
/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work/config/../vendor/rails/actionpack/lib/../../activesupport/lib/active_support/dependencies.rb:477:in `const_missing'
./test/unit/builder_status_test.rb:8:in `setup'
    EOL
    
    assert_equal expected, format_build_log(log)
  end

  def test_format_build_log_links_to_code_knows_about_rails_root
    expected = <<-EOL
<a href="/projects/code/mine/test/unit/builder_status_test.rb?line=8#8">test/unit/builder_status_test.rb:8</a>:in `setup'
<a href="/projects/code/mine/test/unit/builder_status_test.rb?line=8#8">\#{RAILS_ROOT}/test/unit/builder_status_test.rb:8</a>:in `setup'
    EOL
    
    log = <<-EOL
test/unit/builder_status_test.rb:8:in `setup'
\#{RAILS_ROOT}/test/unit/builder_status_test.rb:8:in `setup'
    EOL
    
    assert_equal expected, format_build_log(log)
  end

  def test_format_build_log_doesnt_link_to_code_outside_project
    expected = <<-EOL
../foo:20
<a href="/projects/code/mine/index.html?line=30#30">../work/index.html:30</a>
/ruby/gems/ruby.rb:25
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
Name: test_build_loop_failed_creates_file__build_loop_failed__(BuilderStatusTest)
Type: Error
Message: NameError: uninitialized constant BuilderStatusTest::BuilderStatus

<span class=\"error\">    <a href=\"/projects/code/mine/test/unit/builder_status_test.rb?line=8#8\">./test/unit/builder_status_test.rb:8</a>:in `setup'</span>


Name: test_build_started_creates_file__building__(BuilderStatusTest)
Type: Error
Message: NameError: uninitialized constant BuilderStatusTest::BuilderStatus

<span class=\"error\">    /active_support/dependencies.rb:477:in `const_missing'
    <a href=\"/projects/code/mine/test/unit/builder_status_test.rb?line=8#8\">./test/unit/builder_status_test.rb:8</a>:in `setup'</span>


    EOL
    
    assert_equal expected, failures_and_errors_if_any(log)
  end
  
  BuildStub = Struct.new :label, :time, :state # failed, incomplete
  class BuildStub
    def failed?() @state == 'failed' end
    def incomplete?() @state == 'incomplete' end
  end
  
  def test_select_builds
    @build = BuildStub.new(4)
    
    assert_equal "", select_builds([])
    
    assert_equal "<select id=\"build\" name=\"build\" onChange=\"this.form.submit();\">" +
                 "<option value=''>Older Builds...</option>" +
                 "<option value='1'>1 (1 Jan 06)</option>" +
                 "</select>", select_builds([BuildStub.new(1, Date.new(2006,1,1).to_time)])
    
    @build = BuildStub.new(3)
    assert_equal "<select id=\"build\" name=\"build\" onChange=\"this.form.submit();\">" +
                 "<option value=''>Older Builds...</option>" +
                 "<option value='1'>1 (1 Jan 06)</option>" +
                 "<option value='3'>3 (5 Jan 06)</option>" +
                 "<option value='5'>5 (10 Jan 06)</option>" +
                 "</select>", select_builds([BuildStub.new(1, Date.new(2006,1,1).to_time),
                                             BuildStub.new(3, Date.new(2006,1,5).to_time),
                                             BuildStub.new(5, Date.new(2006,1,10).to_time)])
  end

  def test_builds_except_last
    with_sandbox_project do |sandbox, project|
      project.stubs(:builds).returns((1..10).to_a.map {|i| Build.new(project, i)})
      
      assert_builds [10,9,8,7,6,5,4,3,2,1], builds_except_last(project, 0)
      assert_builds [], builds_except_last(project, 10)
      assert_builds [5,4,3,2,1], builds_except_last(project, 5)
    end
  end
  
  private
  
  def assert_builds(expected, actual)
    assert_equal expected, actual.map{|b| b.label}
  end

  def h(text)
    text
  end
  
end
