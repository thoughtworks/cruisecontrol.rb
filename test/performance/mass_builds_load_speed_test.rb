require File.dirname(__FILE__) + '/../test_helper'
require 'fileutils'

class MassBuildsLoadSpeedTest < ActionController::IntegrationTest
  include FileUtils

  def self.fixture_table_names() return []; end

  def test_load_project_with_many_builds
    projects_root = "#{RAILS_ROOT}/projects"
    mkdir projects_root unless File.exist?(projects_root)
    
    project_root = "#{projects_root}/performance_test"
    
    unless File.exist?(project_root)
      p "create files for performance test"
      mkdir project_root
      mkdir "#{project_root}/work"
      touch "#{project_root}/builder_status.sleeping"
      
      (1..3000).each do |i|
        build_dir = "#{project_root}/build-#{i}"
        cp_r File.dirname(__FILE__) + "/build-sample", project_root
        mv "#{project_root}/build-sample", build_dir
      end
    end

    log_time("START TEST")
    
#    it takes 3 seconds to display dashboard. looks fine.    
    get "/projects"
    log_time("DASHBOARD DISPLAYED")

    get "/projects.js"
    log_time("index.js RENDERED")

#    it takes 5 seconds to display builds default page. looks fine too.
    get "/builds/performance_test"
    log_time("builds DEFAULT PAGE DISPLAYED")
  end  
  
  private
  def log_time(message = "LOG")
    p "== #{message} == : " + Time.now.to_s(:human)
  end
  
  def log_to_file(filename, message)
    touch filename
    File.open(filename, "w"){|f|f.write(message)}
  end
end
