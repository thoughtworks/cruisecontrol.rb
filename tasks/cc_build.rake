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

def cc_invoke(task_name)
  puts "[CruiseControl] Invoking Rake task #{task_name.inspect}"
  Rake::Task[task_name].invoke
end



namespace :cc do

  task 'build' do

    ENV['RAILS_ENV'] ||= 'test'

    # if custom rake task defined, invoke that
    if ENV['CC_RAKE_TASK']
      tasks = ENV['CC_RAKE_TASK'].split(/\s+/)

      undefined_tasks = tasks.collect { |task| Rake.application.lookup(task) ? nil : task }.compact
      raise "Custom rake task(s) '#{undefined_tasks.join(", ")}' not defined" unless undefined_tasks.empty?

      tasks.each { |task| cc_invoke task }

    # if the project defines 'cruise' Rake task, that's all we need to do
    elsif Rake.application.lookup('cruise')
      cc_invoke 'cruise'
    else
      if File.exists?(Dir.pwd + "/config/database.yml") 
        if Dir[Dir.pwd + "/db/migrate/*.rb"].empty?
          raise "No migration scripts found in db/migrate/ but database.yml exists, " +
                "CruiseControl won't be able to build the latest test database. Build aborted." 
        end
        
        # perform standard Rails database cleanup/preparation tasks if they are defined in project
        # this is necessary because there is no up-to-date development database on a continuous integration box
        if Rake.application.lookup('db:test:purge')
          cc_invoke 'db:test:purge'
        end
        if Rake.application.lookup('db:migrate')
          ActiveRecordHelper.connect
          cc_invoke 'db:migrate'
        end
      end
      
      # invoke 'test' or 'default' task
      if Rake.application.lookup('test')
        cc_invoke 'test'
      elsif Rake.application.lookup('default')
        cc_invoke 'default'
      else
        raise "'cruise', test' or 'default' tasks not found. CruiseControl doesn't know what to build."
      end

    end
  end

end



