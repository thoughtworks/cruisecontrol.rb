require File.dirname(__FILE__) + '/../test_helper'

class BuildTest < Test::Unit::TestCase
  include FileSandbox

  def test_initialize_should_load_status_file_and_build_log
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2-success.in9.235s/build_status.success.in9.235s"
      sandbox.new :file => "build-2-success.in9.235s/build.log", :with_content => "some content"
      build = Build.new(project, 2)
  
      assert_equal 2, build.label
      assert_equal true, build.successful?
      assert_equal "some content", build.output
    end
  end

  def test_initialize_should_load_failed_status_file
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-2-failed.in2s/build_status.failed.in2s"
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

  def test_artifacts_directory_method_should_remove_cached_pages
    with_sandbox_project do |sandbox, project|
      build = Build.new(project, 2)
      build.expects(:clear_cache)
      build.artifacts_directory      
    end
    
    project = create_project_stub('one', 'success')
    build = Build.new(project, 1)
    FileUtils.expects(:rm_rf).with("#{RAILS_ROOT}/public/builds/older/#{project.name}")
    build.clear_cache
  end
  
  def test_output_gives_empty_string_when_file_does_not_exist
    with_sandbox_project do |sandbox, project|
      File.expects(:'read').with("#{project.path}/build-1/build.log").raises(StandardError)
      assert_equal "", Build.new(project, 1).output
    end
  end
  
  def test_successful?
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1-success/build_status.success"
      sandbox.new :file => "build-2-Success/build_status.Success"
      sandbox.new :file => "build-3-failure/build_status.failure"
      sandbox.new :file => "build-4-crap/build_status.crap"
      sandbox.new :file => "build-5/foo"
  
      assert Build.new(project, 1).successful?
      assert Build.new(project, 2).successful?
      assert !Build.new(project, 3).successful?
      assert !Build.new(project, 4).successful?
      assert !Build.new(project, 5).successful?
    end
  end

  def test_incomplete?
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1-incomplete/build_status.incomplete"
      sandbox.new :file => "build-2-something_else/build_status.something_else"
  
      assert Build.new(project, 1).incomplete?
      assert !Build.new(project, 2).incomplete?
    end
  end

  def test_run_successful_build
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
  
      build = Build.new(project, 123)
  
      expected_command = build.rake
      expected_build_log = File.join(expected_build_directory, 'build.log')
      expected_redirect_options = {
          :stdout => expected_build_log,
          :stderr => expected_build_log,
          :escape_quotes => false
        }
      Time.expects(:now).at_least(2).returns(Time.at(0), Time.at(3.2))
      build.expects(:execute).with(build.rake, expected_redirect_options).returns("hi, mom!")

      BuildStatus.any_instance.expects(:'succeed!').with(4)
      BuildStatus.any_instance.expects(:'fail!').never
      build.run
    end
  end

  def test_run_stores_settings
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
      project.stubs(:config_file_content).returns("cool project settings")
  
      build = Build.new(project, 123)
      build.stubs(:execute)

      build.run

      assert_equal 'cool project settings', file('build-123-success.in1s/cruise_config.rb').contents
      assert_equal 'cool project settings', Build.new(project, 123).project_settings
    end
  end

  def test_run_unsuccessful_build
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
  
      build = Build.new(project, 123)
  
      expected_build_log = File.join(expected_build_directory, 'build.log')
      expected_redirect_options = {
        :stdout => expected_build_log,
        :stderr => expected_build_log,
        :escape_quotes => false
      }
  
      build.expects(:execute).with(build.rake, expected_redirect_options).raises(CommandLine::ExecutionError)
      Time.stubs(:now).returns(Time.at(1))
      BuildStatus.any_instance.expects(:'fail!').with(0)  
      build.run
    end
  end
  
  def test_warn_on_mistake_check_out_if_trunk_dir_exists
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "work/trunk/rakefile"
    
      expected_build_directory = File.join(sandbox.root, 'build-123')
  
      build = Build.new(project, 123)
  
      expected_build_log = File.join(expected_build_directory, 'build.log')
      expected_redirect_options = {
        :stdout => expected_build_log,
        :stderr => expected_build_log,
        :escape_quotes => false
      }
  
      build.expects(:execute).with(build.rake, expected_redirect_options).raises(CommandLine::ExecutionError)
      build.run
      
      log = File.open("build-123-failed.in1s/build.log"){|f| f.read }
      assert_match /trunk exists/, log
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
  
  def test_build_should_know_about_additional_artifacts
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/coverage/index.html"
      sandbox.new :file => "build-1/coverage/units/index.html"
      sandbox.new :file => "build-1/coverage/functionals/index.html"
      sandbox.new :file => "build-1/foo"
      sandbox.new :file => "build-1/foo.txt"
      sandbox.new :file => "build-1/cruise_config.rb"
      sandbox.new :file => "build-1/plugin_errors.log"
      sandbox.new :file => "build.log"
      sandbox.new :file => "build_status.failure"
      sandbox.new :file => "changeset.log"

      
      build = Build.new(project, 1)
      assert_equal(%w(coverage foo foo.txt), build.additional_artifacts.sort)
    end
  end
  
  def test_build_should_fail_if_project_config_is_invalid
    with_sandbox_project do |sandbox, project|
      expected_build_directory = File.join(sandbox.root, 'build-123')
      project.stubs(:config_file_content).returns("cool project settings")
      project.stubs(:error_message).returns("some project config error")
      project.expects(:'config_valid?').returns(false)
      build = Build.new(project, 123)
      build.run
      assert build.failed?
      log_message = File.open("build-123-failed.in0s/build.log"){|f| f.read }
      assert_equal "some project config error", log_message
    end
  end  
    
  def test_should_pass_error_to_build_status_if_config_file_is_invalid
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build.log"
      project.stubs(:error_message).returns("fail message")
      project.stubs(:"config_valid?").returns(false)
      
      build = Build.new(project, 1)
      build.run
      assert_equal "fail message", File.open("build-1-failed.in0s/error.log"){|f|f.read}
      assert_equal "config error", build.brief_error
    end   
  end
    
  def test_should_pass_error_to_build_status_if_plugin_error_happens
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1-success.in0s/error.log"
      build = Build.new(project, 1)
      build.stubs(:plugin_errors).returns("plugin error")
      assert_equal "plugin error", build.brief_error
    end   
  end    
  
  def test_should_generate_build_url_with_dashboard_url
    with_sandbox_project do |sandbox, project|
      sandbox.new :file => "build-1/build_status.success.in0s"
      build = Build.new(project, 1)

      dashboard_url = "http://www.my.com"
      Configuration.expects(:dashboard_url).returns(dashboard_url)      
      assert_equal "#{dashboard_url}/builds/#{project.name}/#{build.to_param}", build.url
      
      Configuration.expects(:dashboard_url).returns(nil)
      assert_raise(RuntimeError) { build.url }
    end   
  end
end
