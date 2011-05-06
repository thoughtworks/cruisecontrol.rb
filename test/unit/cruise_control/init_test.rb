require 'test_helper'
require Rails.root.join("lib", "cruise_control", "init")

module CruiseControl
  class InitTest < Test::Unit::TestCase
    
    def test_that_method_for_command_accepts_stop
      init = Init.new
      assert_equal(:stop, init.method_for_command('stop'))
    end
    
  end
end