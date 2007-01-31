require File.dirname(__FILE__) + '/../test_helper'

class ServerTest < Test::Unit::TestCase
  include FileSandbox
  
  def test_save_server
    in_sandbox do |sandbox|
      ActionMailer::Base.server_settings = {:foo => 'crap', :port => 13}
      Server.new(sandbox.root).save
      sandbox.assert :file => 'server_config.rb', 
                     :has_contents => 'ActionMailer::Base.server_settings = {:foo=>"crap", :port=>13}'
      
      ActionMailer::Base.server_settings = {:bar => 'cat'}
      Server.new(sandbox.root).load
    
      assert_equal({:foo => 'crap', :port => 13}, ActionMailer::Base.server_settings)
    end
  end
  
  def test_load_server_does_nothing_if_file_doesnt_exist
    Server.new('madeup_dir').load
  end
end