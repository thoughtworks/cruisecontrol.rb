module CruiseControl

  def self.invoke_rake_task(task_name)
    puts "[CruiseControl] Invoking Rake task #{task_name.inspect}"
    Rake::Task[task_name].invoke
  end

  # This hack is needed because db:test:purge implementation for MySQL drops the test database, invalidating
  # the existing connection. A solution is to reconnect again.
  def self.reconnect
    require 'active_record'
    configurations = ActiveRecord::Base.configurations
    if configurations and configurations.has_key?("test") and configurations["test"]["adapter"] == 'mysql'
      ActiveRecord::Base.establish_connection(:test)
    end
  end

end

namespace :cc do

  task 'build' do

    # if custom rake task defined, invoke that
    if ENV['CC_RAKE_TASK']
      tasks = ENV['CC_RAKE_TASK'].split(/\s+/)

      undefined_tasks = tasks.collect { |task| Rake.application.lookup(task) ? nil : task }.compact
      raise "Custom rake task(s) '#{undefined_tasks.join(", ")}' not defined" unless undefined_tasks.empty?

      tasks.each { |task| CruiseControl::invoke_rake_task task }

    # if the project defines 'cruise' Rake task, that's all we need to do
    elsif Rake.application.lookup('cruise')
      CruiseControl::invoke_rake_task 'cruise'
    else

      ENV['RAILS_ENV'] ||= 'test'

      if File.exists?(Dir.pwd + "/config/database.yml")
        if Dir[Dir.pwd + "/db/migrate/*.rb"].empty?
          raise "No migration scripts found in db/migrate/ but database.yml exists, " +
                "CruiseControl won't be able to build the latest test database. Build aborted." 
        end
        
        # perform standard Rails database cleanup/preparation tasks if they are defined in project
        # this is necessary because there is no up-to-date development database on a continuous integration box
        if Rake.application.lookup('db:test:purge')
          CruiseControl::invoke_rake_task 'db:test:purge'
        end
        if Rake.application.lookup('db:migrate')
          CruiseControl::reconnect
          CruiseControl::invoke_rake_task 'db:migrate'
        end
      end
      
      # invoke 'test' or 'default' task
      if Rake.application.lookup('test')
        CruiseControl::invoke_rake_task 'test'
      elsif Rake.application.lookup('default')
        CruiseControl::invoke_rake_task 'default'
      else
        raise "'cruise', test' or 'default' tasks not found. CruiseControl doesn't know what to build."
      end

    end
  end

end
