require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class BuilderStatusTest < Test::Unit::TestCase
  
  def setup
    project = Project.new('project')
    project.path = 'project_root'
    @builder_status = BuilderStatus.new(project)
    @mock_build = Object.new
  end
  
  def test_build_started_creates_file__building__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.building')
    @builder_status.build_started @mock_build
  end  
  
  def test_sleeping_creates_file__sleeping__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.sleeping')
    @builder_status.sleeping
  end
  
  def test_polling_source_control_creates_file__polling_source_control__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.checking_for_modifications')
    @builder_status.polling_source_control
  end

  def test_build_loop_failed_creates_file__build_loop_failed__
    Dir.stubs(:'[]').returns(['project_root/builder_status.foo'])
    FileUtils.expects(:rm_f).with(['project_root/builder_status.foo'])
    FileUtils.expects(:touch).with('project_root/builder_status.error')
    @builder_status.build_loop_failed
  end
  
  def test_return_sleeping_when_file_does_not_exist
    Dir.expects(:'[]').with("project_root/builder_status.*").returns([])
    assert_equal :sleeping, @builder_status.status
  end
    
  def test_return_sleeping_when_file_is__sleeping__
    Dir.expects(:'[]').with("project_root/builder_status.*").returns(['builder_status.sleeping'])
    assert_equal :sleeping, @builder_status.status
  end
  
  def test_return_building_when_file_is__building__
    Dir.expects(:'[]').with("project_root/builder_status.*").returns(['builder_status.building'])
    assert_equal :building, @builder_status.status
  end
  
  def test_return_checking_for_modifications_when_file_is__checking_for_modifications__
    Dir.expects(:'[]').with("project_root/builder_status.*").returns(['builder_status.checking_for_modifications'])
    assert_equal :checking_for_modifications, @builder_status.status  
  end
  
  def test_return_error_when_file_is__error__
    Dir.expects(:'[]').with("project_root/builder_status.*").returns(['builder_status.error'])
    assert_equal :error, @builder_status.status  
  end
    
end