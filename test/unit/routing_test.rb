require File.dirname(__FILE__) + '/../test_helper'

class RoutingTest < Test::Unit::TestCase
  def test_build
    assert_routing 'builds/CruiseControl', {:controller => 'builds', :action => 'show', :project => 'CruiseControl'}
    assert_routing 'builds/CruiseControl/1', 
                    {:controller => 'builds', :action => 'show', :project => 'CruiseControl', :build => '1'}
    assert_routing 'builds/CruiseControl/1.2', 
                    {:controller => 'builds', :action => 'show', :project => 'CruiseControl', :build => '1.2'}
  end

  def test_build_artifacts
    assert_routing 'builds/CruiseControl/1.2/this/stuff.rb', 
                    {:controller => 'builds', :action => 'artifact', :project => 'CruiseControl', :build => '1.2', 
                     :path => ['this', 'stuff.rb']}

  end
end
