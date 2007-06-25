Capistrano.configuration(:must_exist).load do

  desc 'deploy CC.rb'
  task :deploy_ccrb do
    stop_ccrb

    update_code
    after_update_code
    symlink

    start_ccrb
  end

  desc 'stop CC.rb'
  task :stop_ccrb do
    sudo "sv force-stop ccrb_dashboard_1" rescue nil
    sudo "sv force-stop ccrb_dashboard_2" rescue nil
  end

  desc "start CC.rb"
  task :start_ccrb do
    sudo "sv start ccrb_dashboard_1" rescue nil
    sudo "sv start ccrb_dashboard_2" rescue nil
  end

  desc 'Update symlink for projects directory'
  task :after_update_code do
    sudo "rm -rf #{release_path}/projects"
    sudo "mkdir -p #{shared_path}/projects"
    sudo "ln -nfs #{shared_path}/projects #{release_path}/projects"
  end

end