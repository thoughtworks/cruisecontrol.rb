Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do

    desc 'deploy CC.rb'
    task :ccrb do
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
      sudo "chown deployer #{shared_path}/projects"
      sudo "chgrp rails #{shared_path}/projects"
      sudo "ln -nfs #{shared_path}/projects #{release_path}/projects"
      sudo "touch #{shared_path}/site_config.rb"
      sudo "ln -nfs #{shared_path}/site_config.rb #{release_path}/config/site_config.rb"
    end

  end
end
