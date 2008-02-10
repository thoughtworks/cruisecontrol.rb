class Build
  include CommandLine

  attr_reader :project, :label
  IGNORE_ARTIFACTS = /^(\..*|build_status\..+|build.log|changeset.log|cruise_config.rb|plugin_errors.log)$/

  def initialize(project, label)
    @project, @label = project, label.to_s
    @start = Time.now
  end

  def build_status
    BuildStatus.new(artifacts_directory)
  end

  def latest?
    label == project.last_build.label
  end

  def fail!(error = nil)
    build_status.fail!(seconds_since(@start), error)
  end
  
  def run
    build_log = artifact 'build.log'
    File.open(artifact('cruise_config.rb'), 'w') {|f| f << @project.config_file_content }

    begin
      raise ConfigError.new(@project.error_message) unless @project.config_valid?
      in_clean_environment_on_local_copy do
        execute self.command, :stdout => build_log, :stderr => build_log
      end
      build_status.succeed!(seconds_since(@start))
    rescue => e
      if File.exists?(project.local_checkout + "/trunk")
        msg = <<EOF

WARNING:
Directory #{project.local_checkout}/trunk exists.
Maybe that's your APP_ROOT directory.
Try to remove this project, then re-add it with correct APP_ROOT, e.g.

rm -rf #{project.path}
./cruise add #{project.name} svn://my.svn.com/#{project.name}/trunk
EOF
        File.open(build_log, 'a'){|f| f << msg }
      end

      File.open(build_log, 'a'){|f| f << e.message }
      CruiseControl::Log.verbose? ? CruiseControl::Log.debug(e) : CruiseControl::Log.info(e.message)
      if e.is_a?(CommandLine::ExecutionError) # i.e., the build returned a non-zero status code
        fail!
      else
        fail!(e.message)
      end
    end
  end
  
  def brief_error
    return error unless error.blank?
    return "plugin error" unless plugin_errors.empty?
    nil
  end
  
  def destroy
    FileUtils.rm_rf artifacts_directory
  end
  
  alias abort destroy

  def additional_artifacts
    Dir.entries(artifacts_directory).find_all {|artifact| !(artifact =~ IGNORE_ARTIFACTS) }
  end
  
  def status
    build_status.to_s
  end

  def successful?
    build_status.succeeded?
  end

  def failed?
    build_status.failed?
  end

  def incomplete?
    build_status.incomplete?
  end

  def revision
    label.split(".")[0]
  end
  
  def changeset
    @changeset ||= contents_for_display(artifact('changeset.log'))
  end

  def output
    @output ||= contents_for_display(artifact('build.log'))
  end
  
  def project_settings
    @project_settings ||= contents_for_display(artifact('cruise_config.rb'))
  end

  def error
    @project_settings ||= contents_for_display(build_status.error_message_file)
  end

  def plugin_errors
    @plugin_errors ||= contents_for_display(artifact('plugin_errors.log'))
  end

  def time
    build_status.timestamp
  end

  def artifacts_directory
    @artifacts_directory = Dir["#{@project.path}/build-#{label}*"].sort.first || File.join(@project.path, "build-#{label}")
    unless File.exist? @artifacts_directory
      FileUtils.mkdir_p @artifacts_directory
      clear_cache
    end
    @artifacts_directory
  end
  
  def clear_cache
    FileUtils.rm_f "#{RAILS_ROOT}/public/builds/older/#{@project.name}.html"
  end
  
  def url
    dashboard_url = Configuration.dashboard_url
    raise "Configuration.dashboard_url is not specified" if dashboard_url.nil? || dashboard_url.empty?
    dashboard_url + ActionController::Routing::Routes.generate(
        :controller => 'builds', :action => 'show', :project => project, :build => to_param)
  end
  
  def artifact(file_name)
    File.join(artifacts_directory, file_name)
  end

  def contents_for_display(file)
    return '' unless File.file?(file) && File.readable?(file)
    if File.size(file) < 100 * 1024
      File.read(file)
    else
      contents = File.read(file, 100 * 1024)
      "#{file} is over 100 kbytes - too big to display in the dashboard, output is truncated\n\n\n#{contents}"
    end
  end

  def command
    project.build_command or rake
  end
  
  def rake_task
    project.rake_task
  end
  
  def rake
    # Simply calling rake is this convoluted due to idiosyncrazies of Windows, Debian and JRuby. :(
    # ABSOLUTE_RAILS_ROOT is set in config/envirolnment.rb, and is necessary because
    # in_clean_environment__with_local_copy() changes current working directory. Replacing it with RAILS_ROOT doesn't
    # fail any tests, because in test environment (unlike production) RAILS_ROOT is already absolute. 
    # --nosearch flag here prevents CC.rb from building itself when a project has no Rakefile
    # ARGV.clear at the end prevents Test::Unit's AutoRunner from doing anything silly, like trying to require 'cc:rb'
    # Some people saw it happening.
    %{#{Platform.interpreter} -e "require 'rubygems' rescue nil; require 'rake'; load '#{ABSOLUTE_RAILS_ROOT}/tasks/cc_build.rake'; ARGV << '--nosearch'#{CruiseControl::Log.verbose? ? " << '--trace'" : ""} << 'cc:build'; Rake.application.run; ARGV.clear"}
  end

  def in_clean_environment_on_local_copy(&block)
    old_rails_env = ENV['RAILS_ENV']
    ENV['RAILS_ENV'] = nil

    # set OS variable CC_BUILD_ARTIFACTS so that custom build tasks know where to redirect their products
    ENV['CC_BUILD_ARTIFACTS'] = self.artifacts_directory
    # set OS variablea CC_BUILD_LABEL & CC_BUILD_REVISION so that custom build tasks can use them
    ENV['CC_BUILD_LABEL'] = self.label
    ENV['CC_BUILD_REVISION'] = self.revision
    # CC_RAKE_TASK communicates to cc:build which task to build (if self.rake_task is not set, cc:build will try to be
    # smart about it)
    ENV['CC_RAKE_TASK'] = self.rake_task
    Dir.chdir(project.local_checkout) do
      block.call
    end
  ensure
    ENV['RAILS_ENV'] = old_rails_env
  end

  def to_param
    self.label
  end
  
  def elapsed_time
    build_status.elapsed_time
  end

  def elapsed_time_in_progress
    build_status.elapsed_time_in_progress
  end

  def seconds_since(start)
    (Time.now - start).ceil.abs
  end

end
