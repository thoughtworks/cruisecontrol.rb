require File.dirname(__FILE__) + '/../test_helper'

class BuildTest < Test::Unit::TestCase
  include FileSandbox

  def test_initialize_should_load_status_file_and_build_log
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2/build_status.success"
      sandbox.new :file => "build-2/build.log", :with_content => "some content"
      build = Build.new(project, 2)
  
      assert_equal 2, build.label
      assert_equal true, build.successful?
      assert_equal "some content", build.output
    end
  end

  def test_initialize_should_load_failed_status_file
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2/build_status.failed"
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
  
  def test_successful?
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build_status.success"
      sandbox.new :file => "build-2/build_status.Success"
      sandbox.new :file => "build-3/build_status.failure"
      sandbox.new :file => "build-4/build_status.crap"
      sandbox.new :file => "build-5/foo"
  
      assert Build.new(project, 1).successful?
      assert Build.new(project, 2).successful?
      assert !Build.new(project, 3).successful?
      assert !Build.new(project, 4).successful?
      assert !Build.new(project, 5).successful?
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
          :stderr => expected_build_log,
          :escape_quotes => false
        }
      
      build.expects(:execute).with(build.rake, expected_redirect_options).returns("hi, mom!")
      BuildStatus.any_instance.expects(:'succeed!')
      BuildStatus.any_instance.expects(:'fail!').never
  
      build.run
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
        :stderr => expected_build_log,
        :escape_quotes => false
      }
  
      build.expects(:execute).with(build.rake, expected_redirect_options).raises(CommandLine::ExecutionError)
      BuildStatus.any_instance.expects(:'fail!')
  
      build.run
    end
  end
  
  def test_status
    with_sandbox_project do |sandbox, project|
      BuildStatus.any_instance.expects(:to_s)
      Build.new(project, 123).status
    end
  end

  def test_build_command_customization
    with_sandbox_project do |sandbox, project|
      build_with_defaults = Build.new(project, '1')
      assert_match(/cc_build.rake'; ARGV << '--nosearch' << 'cc:build'/, build_with_defaults.command)
      assert_nil build_with_defaults.rake_task
  
      project.rake_task = 'my_build_task'
      build_with_custom_rake_task = Build.new(project, '2')
      assert_match(/cc_build.rake'; ARGV << '--nosearch' << 'cc:build'/, build_with_custom_rake_task.command)
      assert_equal 'my_build_task', build_with_custom_rake_task.rake_task
  
      project.rake_task = nil
      project.build_command = 'my_build_script.sh'
      build_with_custom_script = Build.new(project, '3')
      assert_equal 'my_build_script.sh', build_with_custom_script.command
      assert_nil build_with_custom_script.rake_task
    end
  end
  
  def test_label_should_be_convert_to_int_if_no_mantissa
    project = Object.new
    project.expects(:path).returns("a_path")
    FileUtils.stubs(:mkdir_p)
    assert_equal 3, Build.new(project, 3.0).label
  end
  
  def test_label_should_keep_to_float_if_there_is_mantissa
    project = Object.new
    project.expects(:path).returns("a_path")
    FileUtils.stubs(:mkdir_p)
    assert_equal 3.2, Build.new(project, 3.2).label
  end

  def test_build_should_know_about_additional_artifacts
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/coverage/index.html"
      sandbox.new :file => "build-1/coverage/units/index.html"
      sandbox.new :file => "build-1/coverage/functionals/index.html"
      sandbox.new :file => "build-1/foo"
      sandbox.new :file => "build-1/foo.txt"
      sandbox.new :file => "build.log"
      sandbox.new :file => "build_status.failure"
      sandbox.new :file => "changeset.log"
      
      build = Build.new(project, 1)
      assert_equal(%w(coverage foo foo.txt), build.additional_artifacts.sort)
    end
  end

  def test_build_should_know_its_publish_name
    with_sandbox_project do |sandbox, project|
      build = Build.new(project, 1)
      assert_equal "/builds/my_project/1", build.publish_name 
    end
  end
end
