Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do

    desc 'deploy CC.rb'
    task :default do
      stop_ccrb

      update_code
      after_update_code
      symlink

      start_ccrb
    end

    task :rollback do
      stop_ccrb

      rollback_code
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
      sudo "chmod -R 775 #{release_path}/tmp"
      sudo "chmod -R 775 #{release_path}/log"
      sudo "rm -rf #{release_path}/projects"
      sudo "mkdir -p #{shared_path}/projects"
      sudo "chmod -R 775 #{shared_path}/projects"
      sudo "chown deployer:rails #{shared_path}/projects"
      sudo "ln -nfs #{shared_path}/projects #{release_path}/projects"
    end

  end
end
