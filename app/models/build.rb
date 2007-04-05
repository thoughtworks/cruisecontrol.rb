class Build
  include CommandLine

  attr_reader :project, :label
  IGNORE_ARTIFACTS = /^(\..*|build_status\..+|build.log|changeset.log|cruise_config.rb|plugin_errors.log)$/

  def initialize(project, label)
    @project, @label = project, label
  end

  def build_status
    BuildStatus.new(artifacts_directory)
  end

  def run
    File.open(artifact('cruise_config.rb'), 'w') {|f| f << @project.config_file_content }
    
    raise ConfigError.new(@project.error_message) unless @project.config_valid?
    
    # build_command must be set before doing chdir, because there may be some relative paths
    build_command = self.command
    time = Time.now

    build_log = artifact 'build.log'
    in_clean_environment_on_local_copy do
      execute build_command, :stdout => build_log, :stderr => build_log, :escape_quotes => false
    end
    build_status.succeed!((Time.now - time).ceil)    
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
    time_escaped = (Time.now - (time || Time.now)).ceil
    if e.is_a? ConfigError
      build_status.fail!(time_escaped, e.message)
    else
      build_status.fail!(time_escaped)
    end
  end
  
  def brief_error
    return nil unless build_status.error_message_file
    if File.size(build_status.error_message_file) > 0
      return "config error"
    end
    unless plugin_errors.empty?
      return "plugin error"
    end
    nil
  end
  
  def abort
    FileUtils.rm_rf artifacts_directory
  end

  def additional_artifacts
    Dir.entries(artifacts_directory).find_all {|artifact| !(artifact =~ IGNORE_ARTIFACTS) }
  end
  
  def status
    build_status.to_s
  end
  
  def status=(value)
    FileUtils.rm_f(Dir["#{artifacts_directory}/build_status.*"])
    FileUtils.touch(artifact("build_status.#{value}"))
    build_status = value
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
  
  def changeset
    File.read(artifact('changeset.log')) rescue ''
  end

  def output
    File.read(artifact('build.log')) rescue ''
  end
  
  def project_settings
    File.read(artifact('cruise_config.rb')) rescue ''
  end

  def plugin_errors
    File.read(artifact('plugin_errors.log')) rescue ''
  end

  def time
    build_status.timestamp
  end

  def artifacts_directory
    @artifacts_directory = Dir["#{@project.path}/build-#{label}*"].first || File.join(@project.path, "build-#{label}")
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

  def command
    project.build_command or rake
  end
  
  def rake_task
    project.rake_task
  end
  
  def rake
    # --nosearch flag here prevents CC.rb from building itself when a project has no Rakefile
    %{ruby -e "require 'rubygems' rescue nil; require 'rake'; load '#{File.expand_path(RAILS_ROOT)}/tasks/cc_build.rake'; ARGV << '--nosearch'#{CruiseControl::Log.verbose? ? " << '--trace'" : ""} << 'cc:build'; Rake.application.run"}
  end

  def in_clean_environment_on_local_copy(&block)
    # set OS variable CC_BUILD_ARTIFACTS so that custom build tasks know where to redirect their products
    ENV['CC_BUILD_ARTIFACTS'] = self.artifacts_directory
    # CC_RAKE_TASK communicates to cc:build which task to build (if self.rake_task is not set, cc:build will try to be
    # smart about it)
    ENV['CC_RAKE_TASK'] = self.rake_task
    Dir.chdir(project.local_checkout) do
      block.call
    end
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

end
