# Project-specific configuration for CruiseControl.rb

Project.configure do |project|

  # Send email notifications about broken and fixed builds to email1@your.site, email2@your.site (default: send to nobody)
  project.email_notifier.emails = ['neev-futuresinc@neevtech.com']
  project.sequential_build_logger.enabled = true
  project.sequential_build_logger.show_in_artifacts = true

  project.log_publisher.globs = []


  # Set email 'from' field to john@doe.com:
  # project.email_notifier.from = 'cireport@neevtech.com'

  # Build the project by invoking rake task 'custom'
  # project.rake_task = 'custom'

  # Build the project by invoking shell script "build_my_app.sh". Keep in mind that when the script is invoked,
  # current working directory is <em>[cruise&nbsp;data]</em>/projects/your_project/work, so if you do not keep build_my_app.sh
  # in version control, it should be '../build_my_app.sh' instead
  # project.build_command = 'build_my_app.sh'
  project.build_command = "rake cruise --trace RAILS_ENV=test"

  # Set the frequency to poll the repository, to check if there are source control changes
  project.scheduler.polling_interval = 1.hour

  # Whether to always build at each polling
  # project.scheduler.always_build = true # to build no matter whether there are source control changes or not
  project.scheduler.always_build = false # to build only when there are source control changes
   
  # Set a regular build interval. A build will always be started at each interval,
  # no matter whether there are source control changes or not; no matter what is the project.scheduler.always_build setting.
  # project.triggered_by ScheduledBuildTrigger.new(project, :build_interval => 1.day, :start_time => 2.minutes.from_now)

  # Set environment variables passed into the build
  # project.environment['DB_HOST'] = 'db.example.com'
  # project.environment['DB_PORT'] = '1234'

  # Set any args for bundler here
  # Defaults to '--path=#{project.gem_install_path} --gemfile=#{project.gemfile} --no-color'
  # project.bundler_args = "--path=#{project.gem_install_path} --gemfile=#{project.gemfile} --no-color --local"
end
