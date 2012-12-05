desc 'Custom curise task for RSpec'

module CruiseControl

  def self.invoke_rake_task(task_name)
    Rake::Task[task_name].invoke
  end

  # This hack is needed because db:test:purge implementation for MySQL drops the test database, invalidating
  # the existing connection. A solution is to reconnect again.
  def self.reconnect
    require 'active_record' unless defined? ActiveRecord
    configurations = ActiveRecord::Base.configurations
    if configurations and configurations.has_key?("test") and configurations["test"]["adapter"] == 'mysql2'
      ActiveRecord::Base.establish_connection(:test)
    end
  end

end

task :cruise do
      ENV['RAILS_ENV'] = 'test'

      if !File.exists?(Dir.pwd + "/config/database.yml")
        example_config = YAML.load_file(Dir.pwd + "/config/database.yml.example")
        example_config.delete("login")
        example_config.each do |environment,config|
          example_config[environment]["username"] = ENV['CC_DB_USERNAME']
          example_config[environment]["password"] = ENV['CC_DB_PASSWORD']
          example_config[environment]["database"] = ENV['CC_PROJECT_NAME'] + '_' + environment
        end
        File.open(Dir.pwd + "/config/database.yml" , 'w') do |out|
          YAML.dump(example_config, out)
        end
      end
      if Dir[Dir.pwd + "/db/migrate/*.rb"].empty?
        raise "No migration scripts found in db/migrate/ but database.yml exists, " +
          "CruiseControl won't be able to build the latest test database. Build aborted."
      end

      # perform standard Rails database cleanup/preparation tasks if they are defined in project
      # this is necessary because there is no up-to-date development database on a continuous integration box
      if Rake.application.lookup('db:test:purge')
        begin
          CruiseControl::invoke_rake_task 'db:test:purge'
        rescue
          CruiseControl::invoke_rake_task 'db:create'
        end
      end

      if Rake.application.lookup('db:migrate')
        CruiseControl::reconnect
        CruiseControl::invoke_rake_task 'db:migrate'
      end

      begin
        CruiseControl::invoke_rake_task 'spec'
      ensure
        out = ENV['CC_BUILD_ARTIFACTS']
        mkdir_p out unless File.directory? out if out
        system("rails_best_practices -f html . ")
        mv 'rails_best_practices_output.html' , "#{out}/rails_best_practices_output.html" if out
        mv 'coverage' , "#{out}/test coverage" if out
        mv 'spec_output.html' , "#{out}/spec_report.html" if out
      end
end
