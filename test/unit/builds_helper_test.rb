require 'test_helper'

class BuildsHelperTest < ActionView::TestCase
  include FileSandbox
  include BuildsHelper
  include ApplicationHelper
  
  setup do
    @work_path = File.expand_path('/Users/jeremy/src/cruisecontrolrb/builds/CruiseControl/work')
    @project = Project.new(:name => 'mine', :scm => FakeSourceControl.new)
  end

  context "#format_build_log" do
    test "should wrap a test-results div around the examples and failures text" do
      assert_equal "Finished in 0.00723 seconds\n\n<div class=\"test-results\">3 examples, 2 failures</div> foo",
        format_build_log("Finished in 0.00723 seconds\n\n3 examples, 2 failures foo")
    end

    test "should wrap a test-results div around RSpec results text" do
      assert_equal "limes <div class=\"test-results\">5 tests, 20 assertions, 10 failures, 2 errors</div> foo",
        format_build_log("limes 5 tests, 20 assertions, 10 failures, 2 errors foo")
    end

    test "should link to the right code location when it detects a code reference in a stack trace" do
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

    test "should link to the right code location and understand paths that are relative to Rails root" do
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

    test "should not attempt to link to code that exists outside the current project" do
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

    test "should strip ANSI color codes if encountered" do
      log_with_ansi_colors = <<-EOF
        \e[32mGREEN\e[0m
        \e[31mRED\e[0m
        BLACK
      EOF

      expected_output = <<-EOF
        GREEN
        RED
        BLACK
      EOF
      assert_equal expected_output, format_build_log(log_with_ansi_colors)    
    end
  end

  context "#failures_and_errors_if_any" do
    test "should pass a high-level functional test that excercises it" do
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
      
      failures_and_errors = failures_and_errors_if_any(log)
      assert_equal 2, failures_and_errors.length
      assert_equal "test_build_loop_failed_creates_file__build_loop_failed__(BuilderStatusTest)", failures_and_errors.first.test_name
    end
  end
  
  class BuildStub < Struct.new(:label, :time, :state)
    def failed?;           @state == 'failed'; end
    def incomplete?;       @state == 'incomplete'; end
    alias_method :abbreviated_label, :label
    alias_method :id, :label
  end
  
  context "#select_builds" do
    test "should return an empty string given an empty build list" do
      project = stub(:id => "foo")
      assert_equal "", select_builds(project, [])
    end

    test "should return a select box tag with one build and a default item given a single build" do
      project = stub(:id => "foo")

      expected_html = content_tag("select", :id => "build", :name => "build") do
        content_tag("option", "Older Builds...", :value => "") + "\n" +
        content_tag("option", "1 (1 Jan 06)", :value => build_path(project.id, 1))
      end

      assert_equal expected_html, select_builds(project, [BuildStub.new(1, Date.new(2006,1,1).to_time)])
    end

    test "should return a select box tag with each build and a default item given multiple builds" do
      builds = [
        BuildStub.new(1, Date.new(2006,1,1).to_time),
        BuildStub.new(3, Date.new(2006,1,5).to_time),
        BuildStub.new(5, Date.new(2006,1,10).to_time)
      ]

      project = stub(:id => "foo")

      expected_html = content_tag("select", :id => "build", :name => "build") do
        content_tag("option", "Older Builds...", :value => "") + "\n" +
        content_tag("option", "1 (1 Jan 06)", :value => build_path(project.id, 1)) + "\n" + 
        content_tag("option", "3 (5 Jan 06)", :value => build_path(project.id, 3)) + "\n" +
        content_tag("option", "5 (10 Jan 06)", :value => build_path(project.id, 5))
      end

      assert_equal expected_html, select_builds(project, builds)
    end
  end

end
