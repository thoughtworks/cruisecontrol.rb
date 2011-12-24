require 'test_helper'

class RoutingTest < ActionController::TestCase
  
  context "project routes" do
    test "should match project correctly" do
      assert_routing '/projects/CruiseControl',
      :controller => 'projects',
      :action => 'show',
      :id => 'CruiseControl'
    end
    
    test "should match project format correctly for rss/json/hmtl" do
      ['rss', 'json', 'html'].each do |format|
        assert_routing "projects/CruiseControl.#{format}",
        :controller => 'projects',
        :action => 'show',
        :id => 'CruiseControl',
        :format => format
      end
    end
    
    test "should match getting started correctly" do
      assert_routing 'projects/CruiseControl/getting_started',
        :controller => 'projects',
        :action => 'getting_started',
        :id => 'CruiseControl'
    end
      
    test "should match code and path correctly" do
      assert_routing '/projects/code/CruiseControl/my/code.rb',
        :controller => 'projects',
        :action => 'code',
        :id => 'CruiseControl',
        :path => 'my/code.rb'
    end
  end
  
  context "build routes" do
    test "should match project and build correctly" do
      assert_routing '/builds/CruiseControl', 
        :controller => 'builds', 
        :action => 'show', 
        :project => 'CruiseControl'
      
      assert_routing '/builds/CruiseControl/1', 
        :controller => 'builds', 
        :action => 'show', 
        :project => 'CruiseControl', 
        :build => '1'
      
      assert_routing '/builds/CruiseControl/1.2', 
        :controller => 'builds', 
        :action => 'show', 
        :project => 'CruiseControl', 
        :build => '1.2'
    end
    
    test "should match latest successful build correctly" do
      assert_routing '/builds/CruiseControl/latest_successful',
        :controller => 'builds',
        :action => 'latest_successful',
        :project => 'CruiseControl'
    end
  
    test "should match artifacts correctly" do
      assert_routing '/builds/CruiseControl/1.2/artifacts/this/stuff.rb', 
        :controller => 'builds', 
        :action => 'artifact', 
        :project => 'CruiseControl', 
        :build => '1.2', 
        :path => 'this/stuff.rb'
    end
  end

  context "documentation routes" do
    test "should match documentation root correctly" do
      assert_routing '/documentation',
        :controller => 'documentation',
        :action => 'get'
    end
    
    test "should match plugins section correctly" do
      assert_routing '/documentation/plugins',
        :controller => 'documentation',
        :action => 'plugins'
    end
  end
  
  context "reporting routes" do 
    test "should support cctray/ccmenu" do
      assert_routing '/.cctray',
        :controller => 'projects',
        :action => 'index',
        :format => 'cctray'
      
      assert_recognizes({
                          :controller => 'projects',
                          :action => 'index',
                          :format => 'cctray'
                        },
                        {
                          :path => 'XmlStatusReport.aspx',
                          :method => 'get'
                        })
      
       assert_recognizes({
                           :controller => 'projects',
                           :action => 'index',
                           :format => 'cctray'},
                         {
                           :path => 'XmlServerReport.aspx',
                           :method => 'get'
                         })
    end
  end
end
