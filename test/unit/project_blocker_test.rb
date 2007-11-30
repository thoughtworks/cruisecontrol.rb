require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ProjectBlockerTest < Test::Unit::TestCase
  def setup
    @project = Object.new
    @project.stubs(:name).returns("foo")
    @project.stubs(:path).returns(".")
    
    @lock = Object.new
    FileLock.expects(:new).returns(@lock)
  end
  
  def test_block
    @lock.expects(:lock)
    ProjectBlocker.block(@project)
  end
  
  def test_release
    @lock.expects(:release)
    ProjectBlocker.release(@project)
  end
  
  def test_blocked?
    @lock.expects(:locked?).returns(true)
    assert ProjectBlocker.blocked?(@project)
  end
end