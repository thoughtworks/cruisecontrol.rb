require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'build_reaper'
class BuildReaperTest < Test::Unit::TestCase
  include FileSandbox
  include BuildFactory
  
  def setup
    setup_sandbox
    @reaper = BuildReaper.new(the_project)
  end
  
  def teardown
    BuildReaper.number_of_builds_to_keep = nil
    teardown_sandbox
  end
    
  def test_should_read_configuration_and_respond_to_build_finished_event
    BuildReaper.number_of_builds_to_keep = 5
    @reaper.expects(:delete_all_builds_but).with(5)
    
    @reaper.build_finished(nil)
  end
  
  def test_should_delete_directories
    create_builds *(1..9)
    
    @reaper.delete_all_builds_but 4
    
    assert_equal %w(build-6 build-7 build-8 build-9), Dir["*"].sort
  end
  
  def test_should_delete_no_builds
    create_build 1
    
    @reaper.delete_all_builds_but 2
    
    assert_equal %w(build-1), Dir["*"]
  end
end