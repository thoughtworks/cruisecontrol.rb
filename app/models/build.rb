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
    build_log = artifact('build.log')
    build_log_path = build_log.expand_path.to_s
    artifact('cruise_config.rb').open('w') {|f| f << @project.config_file_content }

    begin
      raise ConfigError.new(@project.error_message) unless @project.config_valid?
      in_clean_environment_on_local_copy do
        if @project.uses_bundler?
          execute self.bundle_install, :stdout => build_log_path, :stderr => build_log_path, :env => project.environment
        end
        execute self.command, :stdout => build_log_path, :stderr => build_log_path, :env => project.environment
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
        build_log.open('a') { |f| f << msg }
      end

      build_log.open('a') { |f| f << e.message }

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

  def build_log
    artifact('build.log')
  end

  def output
    @output ||= contents_for_display(build_log)
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

  def files_in(path)
    Dir["#{artifacts_directory}/#{path}/*"].collect {|f| f.gsub("#{artifacts_directory}/", '') }
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
    Pathname.new(artifacts_directory).join(path)
  end

  def exceeds_max_file_display_length?(file)
    file.exist? && Configuration.max_file_display_length.present? && file.size > Configuration.max_file_display_length
  end

  def output_exceeds_max_file_display_length?
    exceeds_max_file_display_length?(artifact('build.log'))
  end

  def contents_for_display(file)
    return '' unless file.file? && file.readable?

    file.read(Configuration.max_file_display_length)
  end

  def command
    project.build_command or rake
  end
  
  def rake_task
    project.rake_task
  end

  def bundle_install
    [ 
      bundle("check", "--gemfile=#{project.gemfile}"),
      bundle("install", project.bundler_args)
    ].join(" || ")
  end

  def rake
    # Simply calling rake is this convoluted due to idiosyncrasies of Windows, Debian and JRuby.
    # --nosearch flag here prevents CC.rb from building itself when a project has no Rakefile.
    # ARGV.clear at the end prevents Test::Unit's AutoRunner from doing anything silly.
    cc_build_path = Rails.root.join('tasks', 'cc_build.rake')
    maybe_trace   = CruiseControl::Log.verbose? ? " << '--trace'" : ""
    
    if project.uses_bundler?
      %{BUNDLE_GEMFILE=#{project.gemfile} #{Platform.bundle_cmd} exec rake -e "load '#{cc_build_path}'; ARGV << '--nosearch'#{maybe_trace} << 'cc:build'; Rake.application.run; ARGV.clear"}
    else  
      %{#{Platform.interpreter} -e "require 'rubygems' rescue nil; require 'rake'; load '#{cc_build_path}'; ARGV << '--nosearch'#{maybe_trace} << 'cc:build'; Rake.application.run; ARGV.clear"}
    end
  end
  
  def in_clean_environment_on_local_copy(&block)
    old_rails_env = ENV['RAILS_ENV']
    old_bundle_gemfile = ENV['BUNDLE_GEMFILE']
    old_rails_context_path = ENV['RAILS_RELATIVE_URL_ROOT']

    Bundler.with_clean_env do
      begin
        ENV['RAILS_ENV'] = nil
        ENV['BUNDLE_GEMFILE'] = nil
        ENV['RAILS_RELATIVE_URL_ROOT'] = nil

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
        ENV['BUNDLE_GEMFILE'] = old_bundle_gemfile
        ENV['RAILS_RELATIVE_URL_ROOT'] = old_rails_context_path
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

  private
    
    def bundle(*args)
      ( [ "BUNDLE_GEMFILE=#{project.gemfile}", Platform.bundle_cmd ] + args.flatten ).join(" ")
    end

end
