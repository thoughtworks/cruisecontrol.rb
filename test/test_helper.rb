ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require_dependency 'application'

# Make double-sure the RAILS_ENV is set to test,
# so fixtures are loaded to the right database
silence_warnings { RAILS_ENV = "test" }

require 'test/unit'
require 'action_controller/test_process'
require 'action_controller/integration'
#require 'action_web_service/test_invoke'
require 'breakpoint'
require 'mocha'
require 'stubba'
require "#{RAILS_ROOT}/vendor/file_sandbox/lib/file_sandbox"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true

class Test::Unit::TestCase

  def assert_raises(arg1 = nil, arg2 = nil)
    expected_error = arg1.is_a?(Exception) ? arg1 : nil
    expected_class = arg1.is_a?(Class) ? arg1 : nil
    expected_message = arg1.is_a?(String) ? arg1 : arg2
    begin 
      yield
      fail "expected error was not raised"
    rescue Test::Unit::AssertionFailedError
      raise
    rescue => e
      raise if e.message == "expected error was not raised"
      assert_equal(expected_error, e) if expected_error
      assert_equal(expected_class, e.class, "Unexpected error type raised") if expected_class
      assert_equal(expected_message, e.message, "Unexpected error message") if expected_message.is_a? String
      assert_matched(expected_message, e.message, "Unexpected error message") if expected_message.is_a? Regexp
    end
  end

  def assert_false(expression)
    assert_equal false, expression
  end

  def in_total_sandbox(&block)
    in_sandbox do |sandbox|
      @dir = File.expand_path(sandbox.root)
      @stdout = "#{@dir}/stdout"
      @stderr = "#{@dir}/stderr"
      @prompt = "#{@dir} #{Platform.user}$"
      yield(sandbox)
    end
  end

  def with_sandbox_project(&block)
    in_total_sandbox do |sandbox|
      FileUtils.mkdir_p("#{sandbox.root}/work")

      project = Project.new('my_project')
      project.path = sandbox.root

      yield(sandbox, project)
    end
  end
  
  def create_project_stub(name, last_build_status = 'failed', last_five_builds = [])
    project = Object.new
    project.stubs(:name).returns(name)
    project.stubs(:last_build_status).returns(last_build_status)
    project.stubs(:last_five_builds).returns(last_five_builds)
    project.stubs(:builder_state_and_activity).returns('building')
    project.stubs(:last_build).returns(last_five_builds.last)
    project
  end

  def create_build_stub(label, status, time = Time.at(0))
    build = Object.new
    build.stubs(:label).returns(label)
    build.stubs(:status).returns(status)
    build.stubs(:time).returns(time)
    build.stubs(:failed?).returns(status == 'failed')
    build.stubs(:successful?).returns(status == 'success')
    build.stubs(:in_progress?).returns(status == 'in_progress')
    build.stubs(:changeset).returns("bobby checked something in")
    build
  end

  class FakeSourceControl
    attr_reader :username
    
    def initialize(username)
      @username = username
    end

    def checkout(dir)
      File.open("#{dir}/README", "w") {|f| f << "some text"}
    end

  end  
end
