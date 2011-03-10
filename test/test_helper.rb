ENV["RAILS_ENV"] = "test"
$:.unshift File.join(File.dirname(__FILE__), '..')
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'mocha'
require 'ostruct'

require 'stringio'
require 'fileutils'
require 'date'
require 'xmlsimple'

$LOAD_PATH << File.dirname(__FILE__)
require 'file_sandbox'
require 'build_factory'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true

class Test::Unit::TestCase
  def assert_raise_with_message(types, matcher, message = nil, &block)
    args = [types].flatten + [message]
    exception = assert_raise(*args, &block)
    assert_match matcher, exception.message, message
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
      FileUtils.mkdir_p("#{sandbox.root}/work/.svn")
      
      project = Project.new('my_project')
      project.path = sandbox.root
      
      yield(sandbox, project)
    end
  end
  
  def create_project_stub(name, last_complete_build_status = 'failed', last_five_builds = [])
    project = Object.new
    project.stubs(:name).returns(name)
    project.stubs(:last_complete_build_status).returns(last_complete_build_status)
    project.stubs(:last_five_builds).returns(last_five_builds)
    project.stubs(:builder_state_and_activity).returns('building')
    project.stubs(:last_build).returns(last_five_builds.last)
    project.stubs(:builder_error_message).returns('')
    project.stubs(:to_param).returns(name)
    project.stubs(:path).returns('.')
    
    project.stubs(:last_complete_build).returns(nil)
    last_five_builds.reverse.each do |build|
      project.stubs(:last_complete_build).returns(build) unless build.incomplete?
    end
    
    project
  end
  
  def create_build_stub(label, status, time = Time.at(0))
    build = Object.new
    build.stubs(:label).returns(label)
    build.stubs(:abbreviated_label).returns(label)
    build.stubs(:status).returns(status)
    build.stubs(:time).returns(time)
    build.stubs(:failed?).returns(status == 'failed')
    build.stubs(:successful?).returns(status == 'success')
    build.stubs(:incomplete?).returns(status == 'incomplete')
    build.stubs(:changeset).returns("bobby checked something in")
    build.stubs(:brief_error).returns(nil)
    build
  end
  
end

class FakeSourceControl < SourceControl::AbstractAdapter
  attr_reader :username, :latest_revision
  attr_accessor :path

  def initialize(username = nil)
    @username = username
    @path = "/some/fake/path"
    @latest_revision = nil
  end

  def checkout
    File.open("#{path}/README", "w") {|f| f << "some text"}
  end

  def up_to_date?(reasons)
    true
  end

  def creates_ordered_build_labels?
    true
  end
  
  def add_revision(opts={})
    @latest_revision = FakeRevision.new(opts)
  end
  
  class FakeRevision < SourceControl::AbstractRevision
    attr_reader :message, :number, :time, :author, :files
    
    def initialize(opts={})
      @number  = opts[:number]
      @message = opts[:message]
      @time    = Time.now
      @author  = "gthreepwood@monkeyisland.gov"
      @files   = []
    end
    
    def ==(other); true; end
  
    def to_s
      "#{number}: #{message}"
    end
  end
end

class File
  def inspect
    "File(#{path})"
  end
end
