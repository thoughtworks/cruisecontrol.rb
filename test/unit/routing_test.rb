require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < ActionController::TestCase
  def test_build
    if RUBY_VERSION == '1.8.7'
      puts '!!!!!! Skipping test on Ruby 1.8.7, re-enable after Rails upgrade.  See https://rails.lighthouseapp.com/projects/8994/tickets/867-undefined-method-length-for-enumerable'
    else
      assert_routing 'builds/CruiseControl', {:controller => 'builds', :action => 'show', :project => 'CruiseControl'}
      assert_routing 'builds/CruiseControl/1', 
                      {:controller => 'builds', :action => 'show', :project => 'CruiseControl', :build => '1'}
      assert_routing 'builds/CruiseControl/1.2', 
                      {:controller => 'builds', :action => 'show', :project => 'CruiseControl', :build => '1.2'}
    end
  end

  def test_build_artifacts
    if RUBY_VERSION == '1.8.7'
      puts '!!!!!! Skipping test on Ruby 1.8.7, re-enable after Rails upgrade.  See https://rails.lighthouseapp.com/projects/8994/tickets/867-undefined-method-length-for-enumerable'
    else
      assert_routing 'builds/CruiseControl/1.2/this/stuff.rb', 
                      {:controller => 'builds', :action => 'artifact', :project => 'CruiseControl', :build => '1.2', 
                       :path => ['this', 'stuff.rb']}
    end
  end
end
