require File.dirname(__FILE__) + '/../test_helper'
require File.expand_path(File.dirname(__FILE__) + '/../sandbox')

class BuildTest < Test::Unit::TestCase

  include Sandbox::Helper

  def test_initialize_should_load_status_file_and_build_log
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2/build_status = success"
      sandbox.new :file => "build-2/build.log", :with_content => "some content"
      build = Build.new(project, 2)
  
      assert_equal 2, build.label
      assert_equal true, build.successful?
      assert_equal "some content", build.output
    end
  end

  def test_initialize_should_load__failed_status_file
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2/build_status = failed"
      build = Build.new(project, 2)
  
      assert_equal 2, build.label
      assert_equal true, build.failed?
    end
  end

  def test_output_grabs_log_file_when_file_exists
    with_sandbox_project do |sandbox, project|
      File.expects(:'read').with("#{project.path}/build-1/build.log").returns(['line 1', 'line 2'])
      assert_equal ['line 1', 'line 2'], Build.new(project, 1).output
    end
  end
  
  def test_output_gives_empty_string_when_file_does_not_exist
    with_sandbox_project do |sandbox, project|
      File.expects(:'read').with("#{project.path}/build-1/build.log").raises(StandardError)
      assert_equal "", Build.new(project, 1).output
    end
  end
  
  def test_coverage_reports_reads_correct_coverage_log_file_by_correct_name
    with_sandbox_project do |sandbox, project|
      File.expects(:'read').with("#{project.path}/build-1/coverage-foo.log").returns(['line 1', 'line 2'])
      assert_equal ['line 1', 'line 2'], Build.new(project, 1).coverage_reports[:foo]
    end
  end
  
  def test_coverage_reports_when_file_does_not_exist
    with_sandbox_project do |sandbox, project|
      File.expects(:'read').with("#{project.path}/build-1/coverage-units.log").raises(StandardError)
      assert_equal "", Build.new(project, 1).coverage_reports[:units]
    end
  end

  def test_successful?
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build_status = success"
      sandbox.new :file => "build-2/build_status = Success"
      sandbox.new :file => "build-3/build_status = failure"
      sandbox.new :file => "build-4/build_status = crap"
      sandbox.new :file => "build-5/foo"
  
      assert Build.new(project, 1).successful?
      assert Build.new(project, 2).successful?
      assert !Build.new(project, 3).successful?
      assert !Build.new(project, 4).successful?
      assert !Build.new(project, 5).successful?
    end
  end

  def test_nil_build
    assert_equal '-', Build.nil.time
    assert_equal '-', Build.nil.label
    assert_equal '-', Build.nil.output
    assert_equal :never_built, Build.nil.status
  end

  def test_formatted_time_when_status_file_does_not_exist
    with_sandbox_project do |sandbox, project|
      assert_equal '-', Build.new(project, 1).formatted_time
    end
  end
  
  def test_formatted_time_when_status_file_exists
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build_status = success"
      Status.any_instance.expects(:created_at).returns(Time.local(2006, 5, 3, 14, 33, 50))
      assert_equal "02:33 PM May 03, 2006", Build.new(project, 1).formatted_time
    end
  end
  
  def test_run_successful_build
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
  
      FileUtils.expects(:mkdir_p).with(expected_build_directory).returns(expected_build_directory)
  
      build = Build.new(project, 123)
  
      expected_command = build.rake
      expected_build_log = File.join(expected_build_directory, 'build.log')
      expected_redirect_options = {
          :stdout => expected_build_log,
          :stderr => expected_build_log
        }
      
      build.expects(:execute).with(build.rake, expected_redirect_options).returns("hi, mom!")
      Status.any_instance.expects(:'succeed!')
  
      build.run
  
      build.verify
      FileUtils.verify
    end
  end

  def test_run_unsuccessful_build
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
  
      FileUtils.expects(:mkdir_p).with(expected_build_directory).returns(expected_build_directory)
  
      build = Build.new(project, 123)
  
      expected_build_log = File.join(expected_build_directory, 'build.log')
      expected_redirect_options = {
        :stdout => expected_build_log,
        :stderr => expected_build_log
      }
  
      build.expects(:execute).with(build.rake, expected_redirect_options).raises(CommandLine::ExecutionError)
      Status.any_instance.expects(:'fail!')
  
      build.run
  
      build.verify
      FileUtils.verify
    end
  end

  def test_get_last_build
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build_status = success"
      sandbox.new :file => "build-2/build_status = success"
  
      one, two = Build.new(project, 1), Build.new(project, 2)
  
      assert_equal 1, one.label
      assert_equal nil, one.last
      assert_equal 1, two.last.label
    end
  end
  
  def test_status
    with_sandbox_project do |sandbox, project|
      Status.any_instance.expects(:to_s)
      Build.new(project, 123).status
    end
  end
  
end
