require 'test_helper'

class BuildTest < ActiveSupport::TestCase
  include FileSandbox

  context "#latest?" do
    test "should be true if it's the latest build in its directory" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-2"
        build_old = Build.new(project, 2)

        sandbox.new :directory => "build-3"
        build_latest = Build.new(project, 3)

        assert build_latest.latest?
        assert_false build_old.latest?
      end
    end
  end

  context "#fail!" do
    test "should instantly fail the build" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-1"
        now = Time.now
        Time.stubs(:now).returns(now)
        
        build = Build.new(project, 1)
        
        now += 10.seconds
        Time.stubs(:now).returns(now)
        build.fail!("I tripped")
        
        assert_equal true, build.failed?
        assert_equal "I tripped", build.error
      end
    end
  end

  context "#brief_error" do
    test "should be blank if there is no error" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-1"
        assert_equal nil, Build.new(project, 1).brief_error
      end
    end

    test "should read from the build error log after a failed build" do
      Time.stubs(:now).returns(Time.at(0))
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-1/build.log"
        project.stubs(:error_message).returns("fail message")
        project.stubs(:"config_valid?").returns(false)
        
        build = Build.new(project, 1, true)
        build.run
        assert_equal "fail message", File.open("build-1-failed.in0s/error.log"){|f|f.read}
        assert_equal "fail message", build.brief_error
      end   
    end
    
    test "should include plugin errors if they exist" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-1-success.in0s/error.log"
        build = Build.new(project, 1)
        build.stubs(:plugin_errors).returns("plugin error")
        assert_equal "plugin error", build.brief_error
      end
    end
  end

  context "#initialize" do
    test "should load status file and build log" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-2-success.in9.235s/build.log", :with_content => "some content"
        build = Build.new(project, 2)
    
        assert_equal '2', build.label
        assert_equal true, build.successful?
        assert_equal "some content", build.output
      end
    end

    test "should load failed status file" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-2-failed.in2s"
        build = Build.new(project, 2)
    
        assert_equal '2', build.label
        assert_equal true, build.failed?
      end
    end

    test "should remove cached pages in the artifacts directory" do
      with_sandbox_project do |sandbox, project|
        project = create_project_stub('one', 'success')
        FileUtils.expects(:rm_f).with(Rails.root.join('public', 'builds', 'older', "#{project.name}.html"))
        Build.new(project, 1, true)
      end
    end
  end

  context "#output" do
    test "should include the log file if it exists" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-1/build.log", :with_content => "some content"
        assert_equal "some content", Build.new(project, 1).output
      end
    end

    test "should return an empty string if the log file does not exist" do
      with_sandbox_project do |sandbox, project|
        assert_equal "", Build.new(project, 1).output
      end
    end

    test "should truncate the output if it exceeds the configured display limit" do
      with_sandbox_project do |sandbox, project|
        Configuration.stubs(:max_file_display_length).returns 1.kilobyte
        sandbox.new :file => "build-1/build.log", :with_content => "X" * ( 1.kilobyte + 1.byte )
        assert_equal 1.kilobyte, Build.new(project, 1).output.length
      end
    end

    test "should not truncate the output if the configured display limit is nil" do
      with_sandbox_project do |sandbox, project|
        Configuration.stubs(:max_file_display_length).returns nil
        sandbox.new :file => "build-1/build.log", :with_content => "X" * ( 1.kilobyte + 1.byte )
        assert_equal 1.kilobyte + 1.byte, Build.new(project, 1).output.length
      end      
    end
  end

  context "#exceeds_max_file_display_length?" do
    test "should return false if the file does not exist" do
      assert_equal false, Build.new(stub, 1).exceeds_max_file_display_length?(stub(:exist? => false))
    end

    test "should return false if the configured max file display length is nil" do
      Configuration.stubs(:max_file_display_length).returns nil
      assert_equal false, Build.new(stub, 1).exceeds_max_file_display_length?(stub(:exist? => true))
    end

    test "should return false if the given file size is equal to the configured max file display length" do
      Configuration.stubs(:max_file_display_length).returns 1.kilobyte
      assert_equal false, Build.new(stub, 1.kilobytes).exceeds_max_file_display_length?(stub(:exist? => true, :size => 1.kilobyte))
    end

    test "should return false if the given file size is less than the configured max file display length" do
      Configuration.stubs(:max_file_display_length).returns 1.kilobyte
      assert_equal false, Build.new(stub, 1.kilobytes).exceeds_max_file_display_length?(stub(:exist? => true, :size => 10.bytes))
    end

    test "should return true if the given file size exceeds the configured max file display length" do
      Configuration.stubs(:max_file_display_length).returns 1.kilobyte
      assert_equal true, Build.new(stub, 1.kilobytes).exceeds_max_file_display_length?(stub(:exist? => true, :size => 2.kilobytes))
    end
  end
  
  context "#successful?" do
    test "should return true if the underlying filename indicates the build was a success" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-1-success"
        sandbox.new :directory => "build-2-Success"
        sandbox.new :directory => "build-3-failure"
        sandbox.new :directory => "build-4-crap"
        sandbox.new :directory => "build-5"

        assert Build.new(project, 1).successful?
        assert Build.new(project, 2).successful?
        assert !Build.new(project, 3).successful?
        assert !Build.new(project, 4).successful?
        assert !Build.new(project, 5).successful?
      end
    end
  end

  context "#incomplete?" do
    test "should return true if the underlying filename indicates the build is incomplete" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :directory => "build-1-incomplete"
        sandbox.new :directory => "build-2-something_else"
    
        assert Build.new(project, 1).incomplete?
        assert !Build.new(project, 2).incomplete?
      end
    end
  end

  context "#run" do
    test "should succeed the build given a successful outcome" do
      with_sandbox_project do |sandbox, project|
        expected_build_directory = File.join(sandbox.root, 'build-123')
    
        Time.expects(:now).at_least(2).returns(Time.at(0), Time.at(3.2))
        build = Build.new(project, 123, true)
    
        expected_build_log = File.join(expected_build_directory, 'build.log')
        expected_options = {
            :stdout => expected_build_log,
            :stderr => expected_build_log,
            :env => {}
          }
        build.expects(:execute).with(build.rake, expected_options).returns("hi, mom!")

        BuildStatus.any_instance.expects(:'succeed!').with(4)
        BuildStatus.any_instance.expects(:'fail!').never
        build.run
      end
    end

    test "should store the result of the build in a file" do
      with_sandbox_project do |sandbox, project|
        project.stubs(:config_file_content).returns("cool project settings")
    
        build = Build.new(project, 123, true)
        build.stubs(:execute)

        build.run
        assert_equal 'cool project settings', SandboxFile.new(Dir['build-123-success.in*s/cruise_config.rb'][0]).contents
        assert_equal 'cool project settings', Build.new(project, 123).project_settings
      end
    end

    test "should fail the build given a bad outcome (error)" do
      with_sandbox_project do |sandbox, project|
        expected_build_directory = File.join(sandbox.root, 'build-123')
    
        Time.stubs(:now).returns(Time.at(1))
        build = Build.new(project, 123, true)
    
        expected_build_log = File.join(expected_build_directory, 'build.log')
        expected_options = {
          :stdout => expected_build_log,
          :stderr => expected_build_log,
          :env => {}
        }

        error = RuntimeError.new("hello")
        build.expects(:execute).with(build.rake, expected_options).raises(error)
        BuildStatus.any_instance.expects(:'fail!').with(0, "hello")
        build.run
      end
    end

    test "should warn on a mistaken checkout if trunk dir exists" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "work/trunk/rakefile"
      
        expected_build_directory = File.join(sandbox.root, 'build-123')
    
        build = Build.new(project, 123, true)

        expected_build_log = File.join(expected_build_directory, 'build.log')
        expected_options = {
          :stdout => expected_build_log,
          :stderr => expected_build_log,
          :env => {}
        }
    
        build.expects(:execute).with(build.rake, expected_options).raises(CommandLine::ExecutionError)
        build.run
        
        log = SandboxFile.new(Dir["build-123-failed.in*s/build.log"].first).content
        assert_match /trunk exists/, log
      end
    end

    test "should have an empty error string if it encounters a command line execution error" do
      with_sandbox_project do |sandbox, project|
        build = Build.new(project, 123, true)

        build.expects(:execute).raises(CommandLine::ExecutionError.new(*%w(a b c d e)))
        build.run
        
        assert_equal "", build.error
      end
    end
    
    test "should pass project environment variables to execute" do
      begin
        cc_db_prefix, ENV["CC_DB_PREFIX"] = ENV["CC_DB_PREFIX"], "test_"
        with_sandbox_project do |sandbox, project|
          project.environment["CC_DB_PREFIX"] = "master_"
        
          expected_build_directory = File.join(sandbox.root, 'build-123')
    
          Time.expects(:now).at_least(2).returns(Time.at(0), Time.at(3.2))
          build = Build.new(project, 123, true)
    
          expected_build_log = File.join(expected_build_directory, 'build.log')
          expected_options = {
              :stdout => expected_build_log,
              :stderr => expected_build_log,
              :env => {'CC_DB_PREFIX' => 'master_'}
            }
          build.expects(:execute).with(build.rake, expected_options).returns("hi, mom!")

          BuildStatus.any_instance.expects(:'succeed!').with(4)
          BuildStatus.any_instance.expects(:'fail!').never
          build.run
        end
      ensure
        ENV["CC_DB_PREFIX"] = cc_db_prefix
      end
    end
  end

  context "#status" do
    test "should delegate to BuildStatus for its status value" do
      with_sandbox_project do |sandbox, project|
        BuildStatus.any_instance.expects(:to_s)
        Build.new(project, 123).status
      end
    end
  end

  context "#command" do
    test "should build with a standard Rake task if the underlying project has no build command" do
      with_sandbox_project do |sandbox, project|
        build = Build.new(project, '1')
        assert_match(/cc_build.rake'; ARGV << '--nosearch' << 'cc:build'/, build.command)
        assert_nil build.rake_task
      end
    end

    test "should build with a custom Rake task if the underlying project specified a Rake task" do
      with_sandbox_project do |sandbox, project|
        project.rake_task = 'my_build_task'
        build_with_custom_rake_task = Build.new(project, '2')
        assert_match(/cc_build.rake'; ARGV << '--nosearch' << 'cc:build'/, build_with_custom_rake_task.command)
        assert_equal 'my_build_task', build_with_custom_rake_task.rake_task
      end
    end

    test "should build with a custom command if the underlying project specified a custom command" do
      with_sandbox_project do |sandbox, project|
        project.rake_task = nil
        project.build_command = 'my_build_script.sh'
        build_with_custom_script = Build.new(project, '3')
        assert_equal 'my_build_script.sh', build_with_custom_script.command
        assert_nil build_with_custom_script.rake_task
      end
    end
  end  

  context "#additional_artifacts" do
    test "should include any files left as artifacts in the build directory" do
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
        assert_equal ["coverage/functionals", "coverage/index.html", "coverage/units"], build.files_in('coverage')
      end
    end
  end

  context "#failed?" do
    test "should be true if the underlying build failed" do
      Time.stubs(:now).returns(Time.at(0))
      with_sandbox_project do |sandbox, project|
        project.stubs(:config_file_content).returns("cool project settings")
        project.stubs(:error_message).returns("some project config error")
        project.expects(:'config_valid?').returns(false)
        build = Build.new(project, 123, true)
        build.run
        assert build.failed?
        log_message = File.open("build-123-failed.in0s/build.log"){|f| f.read }
        assert_equal "some project config error", log_message
      end
    end
  end
  
  context "#url" do
    test "should expose a build url based on the dashboard URL in the project configuration" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-1/build_status.success.in0s"
        build = Build.new(project, 1)

        dashboard_url = "http://www.my.com"
        Configuration.expects(:dashboard_url).returns(dashboard_url)      
        assert_equal "#{dashboard_url}/builds/#{project.name}/#{build.to_param}", build.url
      end      
    end

    test "should raise a RuntimeError if the configuration has no dashboard URL" do
      with_sandbox_project do |sandbox, project|
        sandbox.new :file => "build-1/build_status.success.in0s"
        build = Build.new(project, 1)

        Configuration.expects(:dashboard_url).returns(nil)
        assert_raise(RuntimeError) { build.url }
      end
    end
  end

  context "#in_clean_environment_on_local_copy" do
    test "should not pass current RAILS_ENV to the block" do
      begin
        ENV['RAILS_ENV'] = 'craziness'
        with_sandbox_project do |sandbox, project|
          build = Build.new(project, 1)
        
          build.in_clean_environment_on_local_copy do
            assert_equal nil, ENV['RAILS_ENV']
          end
          
          assert_equal 'craziness', ENV['RAILS_ENV']
        end    
      ensure
        ENV['RAILS_ENV'] = 'test'
      end
    end

    test "should not pass BUNDLE_GEMFILE to the block" do
      begin
        bundle_gemfile, ENV["BUNDLE_GEMFILE"] = ENV["BUNDLE_GEMFILE"], "GemfileOld"
        with_sandbox_project do |sandbox, project|
          build = Build.new(project, 1)

          build.in_clean_environment_on_local_copy do
            assert_equal nil, ENV["BUNDLE_GEMFILE"]
          end

          assert_equal "GemfileOld", ENV["BUNDLE_GEMFILE"]
        end
      ensure
        ENV["BUNDLE_GEMFILE"] = bundle_gemfile
      end
    end
  end  

  context "#abbreviated_label" do
    test "should shorten labels that are too long, preserving the extension" do
      with_sandbox_project do |sandbox, project|
        assert_equal "foo", Build.new(project, "foo").abbreviated_label
        assert_equal "foobarb", Build.new(project, "foobarbaz").abbreviated_label
        assert_equal "foo.bar", Build.new(project, "foo.bar").abbreviated_label
        assert_equal "foobarb.quux", Build.new(project, "foobarbaz.quux").abbreviated_label
      end
    end
  end

  context "#command" do
    test "should return the project's build command if it's set" do
      with_sandbox_project do |sandbox, project|
        project.build_command = "build_stuff"
        assert_equal "build_stuff", Build.new(project, "foo").command
      end
    end

    test "should return a Ruby build command that utilizes cc_build.rake if no build_command is given" do
      with_sandbox_project do |sandbox, project|
        build_cmd = Build.new(project, "foo").command
        assert_match /ruby -e/, build_cmd
        assert_match /cc_build.rake/, build_cmd
      end    
    end
  end

  context "#bundle_install" do
    test "should perform both a check before a full install" do
      with_sandbox_project do |sandbox, project|
        bundle_cmd = Build.new(project, "foo").bundle_install
        assert_match /check (.*) || (.*) install/, bundle_cmd
      end        
    end

    test "should use the project's local checkout both for its Gemfile and install location" do
      with_sandbox_project do |sandbox, project|
        project.bundler_args = ["--some-args"]
        bundle_cmd = Build.new(project, "foo").bundle_install
        assert_match /bundle check/, bundle_cmd
        assert_match /--gemfile=#{project.gemfile}/, bundle_cmd
        assert_match /bundle install/, bundle_cmd
        assert_match /--some-args/, bundle_cmd
      end    
    end
  end
end
