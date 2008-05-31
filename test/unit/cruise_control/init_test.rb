require File.dirname(__FILE__) + '/../../test_helper'
require File.dirname(__FILE__) + '/../../../lib/cruise_control/init'

module CruiseControl
  class InitTest < Test::Unit::TestCase
    
    def test_that_method_for_command_accepts_stop
      init = Init.new
      assert_equal(:stop, init.method_for_command('stop'))
    end
    
    def test_that_stop_works_for_mongrel
      init = Init.new
      File.expects(:exist?).with("tmp/pids/mongrel.pid").returns(true)
      Platform.expects(:exec).with("mongrel_rails stop -P tmp/pids/mongrel.pid")
      init.stop
    end
    
  end
end