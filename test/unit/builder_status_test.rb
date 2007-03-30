require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class BuilderStatusTest < Test::Unit::TestCase
  
  def setup
    @project = Project.new('project')
    @project.path = 'project_root'
    @builder_status = BuilderStatus.new(@project)
    @mock_build = Object.new
    ProjectBlocker.stubs(:blocked?).returns(true)
  end
  
  def test_build_initiated_creates_file__building__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.building')
    @builder_status.build_initiated
  end  
 
  def test_sleeping_creates_file__sleeping__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.sleeping')
    @builder_status.sleeping
  end
  
  def test_polling_source_control_creates_file__checking_for_modifications__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.checking_for_modifications')
    @builder_status.polling_source_control
  end
  
  def test_build_loop_failed_creates_file__build_loop_failed__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.error')
    @builder_status.build_loop_failed(nil)
  end
  
  def test_status_should_return_sleeping_when_status_file_does_not_exist
    Dir.expects(:'[]').with('project_root/builder_status.*').returns([])
    @project.stubs(:build_requested?).returns(false)
    assert_equal 'sleeping', @builder_status.status
  end
    
  include FileSandbox
  def test_status_should_return_status_file_extension_when_status_file_exists
    ProjectBlocker.expects(:blocked?).with(@project).returns(true)
    @project.stubs(:build_requested?).returns(false)
    Dir.stubs(:'[]').with('project_root/builder_status.*').returns(['builder_status.raining'])
    assert_equal 'raining', @builder_status.status
  end
  
  def test_status_should_return_builder_down_if_pid_file_is_not_blocked
    ProjectBlocker.expects(:blocked?).with(@project).returns(false)
    assert_equal 'builder_down', @builder_status.status
  end

  def test_status_should_return_build_requested_if the_builder_is_sleeping_or_polling_and_there_is_a_build_requested
    ProjectBlocker.expects(:blocked?).with(@project).returns(true)
    @project.stubs(:build_requested?).returns(true)
    Dir.expects(:'[]').with('project_root/builder_status.*').returns(
        ['builder_status.sleeping'],
        ['builder_status.checking_for_modifications'])

    assert_equal 'build_requested', @builder_status.status
    assert_equal 'build_requested', @builder_status.status
  end

  def test_status_should_return_sleeping_if_the_builder_is_sleeping_and_there_is_no_build_requested
    ProjectBlocker.expects(:blocked?).with(@project).returns(true)
    @project.stubs(:build_requested?).returns(false)
    Dir.stubs(:'[]').with('project_root/builder_status.*').returns(['builder_status.sleeping'])

    assert_equal 'sleeping', @builder_status.status
  end

  def test_status_should_return_checking_for_modifications_if_the_builder_is_checking_and_there_is_no_build_requested
    ProjectBlocker.expects(:blocked?).with(@project).returns(true)
    @project.stubs(:build_requested?).returns(false)
    Dir.stubs(:'[]').with('project_root/builder_status.*').returns(['builder_status.checking_for_modifications'])

    assert_equal 'checking_for_modifications', @builder_status.status
  end
  
  def test_build_loop_failed_should_set_status_according_exception_passed_in
    e = BuilderError.new("message", "status")
    @builder_status.expects(:set_status).with("status", "message")
    @builder_status.build_loop_failed(e)
    
    e = BuilderError.new("message")
    @builder_status.expects(:set_status).with("error", "message")
    @builder_status.build_loop_failed(e)

    e = RuntimeError.new("message")
    @builder_status.expects(:set_status).with("error")
    @builder_status.build_loop_failed(e)
  end

  def test_builder_error_message_should_be_recorded
    in_sandbox do |sandbox|
      sandbox.new :file => "#{@project.path}/builder_status.sleeping", :with_content => ""
      e = BuilderError.new("message", "status")
      @builder_status.build_loop_failed(e)
      log = File.open("#{@project.path}/builder_status.status"){|f| f.read }
      assert_equal "message", log
    end
  end
  
  def test_should_know_fatal_status
    @builder_status.expects(:status).returns("svn_error")
    assert @builder_status.fatal?
  end
  
  def test_should_know_builder_error_message
    in_sandbox do |sandbox|
      sandbox.new :file => "#{@project.path}/builder_status.some_error", :with_content => "error message"
      assert_equal "error message", @builder_status.error_message
    end
  end
end