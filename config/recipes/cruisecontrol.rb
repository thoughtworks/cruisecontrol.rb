Capistrano.configuration(:must_exist).load do
  desc "deploy CC.rb"
  task :deploy_cc_rb do
    stop_cc_rb
    
    update_code
    after_update_code
    symlink
    
    daemon = File.open(File.dirname(__FILE__) + "/../../daemon/cruise"){|f| f.read }
    daemon_path = "#{release_path}/daemon/cruise"
    put daemon, daemon_path
    run "chmod +x #{daemon_path}"
    
    start_cc_rb
  end

  desc "stop CC.rb"
  task :stop_cc_rb do
    run "#{current_release}/daemon/cruise stop" rescue nil
  end
  
  desc "start CC.rb"
  task :start_cc_rb do
    run "#{current_release}/daemon/cruise start"
  end

  desc "Update symlink for projects directory."
  task :after_update_code do
    run <<-CMD
      rm -rf #{release_path}/projects &&
      mkdir -p #{shared_path}/projects &&
      ln -nfs #{shared_path}/projects #{release_path}/projects
    CMD
  end

  desc "Add a project to cruise control."
  task :add_project do
    unless ENV['NAME'] && ENV['URL'] 
      raise ArgumentError, "***** You must specify the NAME and URL parameters to add a project. *****" 
    end   
    run "#{current_release}/cruise add #{ENV['NAME']} –url #{ENV['URL']}"
  end
    
end