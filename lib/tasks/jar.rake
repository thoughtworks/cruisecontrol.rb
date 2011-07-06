require 'tasks/rails_in_a_war'
DIST_DIR = "#{Rails.root}/dist"
DIST_JAR_DIR = "#{DIST_DIR}/jar"

CRUISE_VERSION = CruiseControl::VERSION::STRING
BUILD_NUMBER  = ENV['GO_PIPELINE_COUNTER'] || 'unknown'
GIT_REVISION  = %x[git log -1 --pretty='%h'].chomp

CRUISE_FULL_VERSION = "#{CRUISE_VERSION}-#{BUILD_NUMBER}-#{GIT_REVISION}"

namespace :server_jar do
  SERVER_JAR_DIR = "#{Rails.root}/server_jar"
  TARGET_DIR     = "#{SERVER_JAR_DIR}/target"

  desc "(internal) clean up all built files"
  task :clean do
    rm_rf TARGET_DIR
  end

  desc "(internal) compile the server starter sources"
  RailsInAWar::JavacTask.new(:compile) do |javac|
    javac.src_dir    = "#{SERVER_JAR_DIR}/src"
    javac.dest_dir   = "#{TARGET_DIR}/classes"
    javac.classpath += Dir["#{Rails.root}/vendor/java/jetty/jetty-start*.jar"]
    javac.classpath += Dir["#{Rails.root}/vendor/java/jruby/jruby-complete*.jar"]
    javac.classpath += Dir["#{Rails.root}/vendor/java/logging/log4j*.jar"]
  end

  desc "(internal) create the bootup jar"
  task :main_jar do
    mkdir_p "#{TARGET_DIR}/dist"
    cd "#{TARGET_DIR}/classes" do
      sh("jar cf #{TARGET_DIR}/dist/ccrb-main.jar .")
    end

    cd "#{SERVER_JAR_DIR}/resource" do
      sh("jar uf #{TARGET_DIR}/dist/ccrb-main.jar .")
    end
  end

  desc "(internal) create the gem dependency list"
  task :create_gem_dependency_list do
    program = "#{SERVER_JAR_DIR}/build-lib/create_gem_dependency_list.rb #{Rails.root}/Gemfile #{TARGET_DIR}"
    if defined?(JRUBY_VERSION)
      ruby(program) # this starts up jruby in a different runtime
    else
      sh("#{Rails.root}/script/jruby #{program}") # since we are in MRI land
    end
  end

  desc "(internal) package the jar"
  task :package do |task|
    rm_rf DIST_DIR
    mkdir_p DIST_DIR

    unless defined?(JRUBY_VERSION)
      sh("#{Rails.root}/script/jrake #{task.name}")  # run this in jruby land
      next # and return
    end
    require 'ant'

    jetty_config_dir = "#{SERVER_JAR_DIR}/jetty-config"

    jetty_jars_dir   = "#{Rails.root}/vendor/java/jetty"
    jruby_jars_dir   = "#{Rails.root}/vendor/java/jruby"
    logging_jars_dir = "#{Rails.root}/vendor/java/logging"

    dist_dir         = "#{TARGET_DIR}/dist"

    ant.war :destfile => "#{dist_dir}/ccrb_server.war",
            :webxml => "#{jetty_config_dir}/WEB-INF/web.xml",
            :compress => "true",
            :keepcompression => "false" do

      metainf    :dir => "#{jetty_config_dir}/META-INF"

      lib        :dir => "#{jruby_jars_dir}",
                 :includes => "**/*.jar"

      zipfileset :prefix => "WEB-INF",
                 :dir => "#{jetty_config_dir}/WEB-INF"

      zipfileset :prefix => "WEB-INF/rails",
                 :dir => "#{Rails.root}",
                 :includes => "Gemfile, Gemfile.lock, config.ru"

       zipfileset :prefix => "WEB-INF/rails/config",
                  :dir => "#{Rails.root}/config"

      zipfileset :prefix => "WEB-INF/rails/db",
                 :dir => "#{Rails.root}/db"

      zipfileset :prefix => "WEB-INF/rails/app",
                 :dir => "#{Rails.root}/app"

      zipfileset :prefix => "WEB-INF/rails/lib",
                 :dir => "#{Rails.root}/lib",
                 :excludes => "tasks/**/*.*"

      zipfileset :prefix => "WEB-INF/rails/public",
                 :dir => "#{Rails.root}/public"

      zipfileset :prefix => "WEB-INF/rails/gems/gems",
                 :dir => "#{Bundler.bundle_path}/gems",
                 :includesfile => "#{TARGET_DIR}/gem_paths.files.txt",
                 :excludes => "*/test/**,*/spec/**"

      zipfileset :prefix => "WEB-INF/rails/gems/specifications",
                 :dir => "#{Bundler.bundle_path}/specifications",
                 :includesfile => "#{TARGET_DIR}/gem_specs.files.txt"
    end

    ant.jar :destfile => "#{DIST_JAR_DIR}/ccrb-#{CRUISE_FULL_VERSION}.jar",
            :update => "true",
            :manifest => "#{jetty_config_dir}/META-INF/MANIFEST.MF" do

      zipfileset :prefix => "jetty.home/etc",
                 :dir => "#{jetty_config_dir}/etc"

      # our startup jar
      zipfileset :src => "#{TARGET_DIR}/dist/ccrb-main.jar",
                 :excludes => "META-INF/**/*"

      (Dir["#{jetty_jars_dir}/**/*.jar"] + Dir["#{logging_jars_dir}/**/*.jar"]).each do |jar|
        zipfileset :src => jar,
                   :excludes => "META-INF/**/*"
      end

      zipfileset :src => "#{dist_dir}/ccrb_server.war",
                 :prefix => "webapp"
    end
  end

  task :all => [:clean, :compile, :main_jar, :create_gem_dependency_list, :package]
end

desc "create the server jar"
task :server_jar => ['server_jar:all']
