namespace :cc do

  task 'build' do

    ENV['RAILS_ENV'] ||= 'test'

    # if custom rake task defined, invoke that
    if ENV['CC_RAKE_TASK']
      custom_task = ENV['CC_RAKE_TASK']
      raise "Custom rake task '#{custom_task}' not defined" unless Rake.application.lookup(custom_task)
      Rake::Task[custom_task].invoke
    # if the project defines 'cruise' Rake task, that's all we need to do
    elsif Rake.application.lookup('cruise')
      Rake::Task['cruise'].invoke
    else
      # perform standard Rails database cleanup/preparation tasks if they are defined in project
      # this is necessary because there is no up-to-date development database on a continuous integration box
      if Rake.application.lookup('db:test:purge')
        Rake::Task['db:test:purge'].invoke
      end
      if Rake.application.lookup('db:migrate')
        Rake::Task['db:migrate'].invoke
      end

      # invoke 'test' or 'default' task
      if Rake.application.lookup('test')
      elsif Rake.application.lookup('default')
        Rake::Task['default'].invoke
      else
        raise "'cruise', test' or 'default' tasks not found. CruiseControl doesn't know what to build."
      end
      
    end
  end

end
