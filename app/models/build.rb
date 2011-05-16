# A Build represents a single build of a particular Project. It possesses all of the attributes
# typically associated with a CI build, such as revision, status, and changeset.
class Build
  include CommandLine
  
  class ConfigError < StandardError; end

  attr_reader :project, :label
  IGNORE_ARTIFACTS = /^(\..*|build_status\..+|build.log|changeset.log|cruise_config.rb|plugin_errors.log)$/

  def initialize(project, label, initialize_artifacts_directory=false)
    @project, @label = project, label.to_s
    @start = Time.now
    if initialize_artifacts_directory
      unless File.exist? artifacts_directory
        FileUtils.mkdir_p artifacts_directory
        clear_cache
      end
    end
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
        if @project.uses_bundler?
          execute self.bundle_install, :stdout => build_log, :stderr => build_log
        end
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
    Dir["#{@project.path}/build-#{label}*"].sort.first || File.join(@project.path, "build-#{label}")
  end
  
  def clear_cache
    FileUtils.rm_f Rails.root.join(Rails.root, 'public', 'builds', 'older', "#{@project.name}.html")
  end
  
  def url
    dashboard_url = Configuration.dashboard_url
    raise "Configuration.dashboard_url is not specified" if dashboard_url.nil? || dashboard_url.empty?
    dashboard_url + Rails.application.routes.url_helpers.build_path(:project => project, :build => to_param)
  end
  
  def artifact(path)
    File.join(artifacts_directory, path)
  end

  def contents_for_display(file)
    return '' unless File.file?(file) && File.readable?(file)
    file_size_kbytes = File.size(file) / 1024
    if file_size_kbytes < 100
      File.read(file)
    else
      contents = File.read(file, 100 * 1024)
      response = "#{file} is #{file_size_kbytes} kbytes - too big to display in the dashboard, the output is truncated\n\n\n"
      response += contents
    end
  end

  def command
    project.build_command or rake
  end
  
  def rake_task
    project.rake_task
  end

  def bundle_install
    vendor  = File.join project.local_checkout, "vendor"
    Platform.bundle_cmd + %{ check --gemfile=#{project.gemfile} } + "||" + Platform.bundle_cmd + %{ install --path=#{vendor} --gemfile=#{project.gemfile} --no-color }
  end

  def rake
    # Simply calling rake is this convoluted due to idiosyncrasies of Windows, Debian and JRuby.
    # --nosearch flag here prevents CC.rb from building itself when a project has no Rakefile.
    # ARGV.clear at the end prevents Test::Unit's AutoRunner from doing anything silly.
    cc_build_path = Rails.root.join('tasks', 'cc_build.rake')
    maybe_trace   = CruiseControl::Log.verbose? ? " << '--trace'" : ""
    
    if project.uses_bundler?
      %{BUNDLE_GEMFILE=#{project.gemfile} } + Platform.bundle_cmd + %{ exec rake -e "load '#{cc_build_path}'; ARGV << '--nosearch'#{maybe_trace} << 'cc:build'; Rake.application.run; ARGV.clear"}
    else  
      Platform.interpreter + %{ -e "require 'rubygems' rescue nil; require 'rake'; load '#{cc_build_path}'; ARGV << '--nosearch'#{maybe_trace} << 'cc:build'; Rake.application.run; ARGV.clear"}
    end
  end
  
  def in_clean_environment_on_local_copy(&block)
    old_rails_env = ENV['RAILS_ENV']

    Bundler.with_clean_env do
      begin
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

  def seconds_since(start)
    (Time.now - start).ceil.abs
  end

  def abbreviated_label
    revision, rebuild_number = label.split('.')
    [revision[0..6], rebuild_number].compact.join('.')
  end

end
