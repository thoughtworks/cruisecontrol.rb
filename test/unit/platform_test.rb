require 'test_helper'

class PlatformTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_create_child_process_detaches_to_avoid_zombie_processes
    Platform.expects(:fork).returns(123)
    Process.expects(:detach).with(123)
    
    Platform.create_child_process("project", "command")
  end
  
end
