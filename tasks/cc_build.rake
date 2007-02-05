class ActiveRecordHelper  
  def self.connect
    require 'active_record'
    abcs = ActiveRecord::Base.configurations
    return if abcs.nil? || abcs["test"].nil?
    case abcs["test"]["adapter"]
      when "mysql"
        ActiveRecord::Base.establish_connection(:test)      
    end
  end
end



namespace :cc do

  task 'build' do

    ENV['RAILS_ENV'] ||= 'test'

    # if custom rake task defined, invoke that
    if ENV['CC_RAKE_TASK']
      tasks = ENV['CC_RAKE_TASK'].split(/\s+/)

      undefined_tasks = tasks.collect { |task| Rake.application.lookup(task) ? nil : task }.compact
      raise "Custom rake task(s) '#{undefined_tasks.join(", ")}' not defined" unless undefined_tasks.empty?

      tasks.each { |task| Rake::Task[task].invoke }

    # if the project defines 'cruise' Rake task, that's all we need to do
    elsif Rake.application.lookup('cruise')
      Rake::Task['cruise'].invoke
    else
      if File.exists?(Dir.pwd + "/config/database.yml") 
        if Dir[Dir.pwd + "/db/migrate/*.rb"].empty?
          raise "No migration scripts found in db/migrate/ but database.yml exists, " +
                "CruiseControl won't be able to build the latest test database. Build aborted." 
        end
        
        # perform standard Rails database cleanup/preparation tasks if they are defined in project
        # this is necessary because there is no up-to-date development database on a continuous integration box
        if Rake.application.lookup('db:test:purge')
          Rake::Task['db:test:purge'].invoke
        end
        if Rake.application.lookup('db:migrate')
          ActiveRecordHelper.connect
          Rake::Task['db:migrate'].invoke
        end
      end
      
      # invoke 'test' or 'default' task
      if Rake.application.lookup('test')
        Rake::Task['test'].invoke
      elsif Rake.application.lookup('default')
        Rake::Task['default'].invoke
      else
        raise "'cruise', test' or 'default' tasks not found. CruiseControl doesn't know what to build."
      end

    end
  end

end



