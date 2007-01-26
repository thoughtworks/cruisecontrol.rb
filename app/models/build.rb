class Build
  include CommandLine

  class << self
    def nil
      NilBuild.new
    end
  end

  attr_reader :project, :label

  def initialize(project, label)
    @project, @label = project, label
    FileUtils.mkdir_p(artifacts_directory)

    @status = Status.new(artifacts_directory)
  end

  def run
    build_log = artifact 'build.log'
    # it's important to figure out build command before doing chdir, because it may be expanding some relative paths
    build_command = self.command
    in_clean_environment_on_local_copy do
      execute build_command, :stdout => build_log, :stderr => build_log, :escape_quotes => false
    end
    @status.succeed!
  rescue => e
    Log.info "==================== BUILD FAILED ========================="
    Log.info e.message
    Log.info e.backtrace.join("\n")
    @status.fail!
  end
  
  def successful?
    @status.succeeded?
  end

  def failed?
    @status.failed?
  end
  
  def status
    @status.to_s
  end
  
  def status=(value)
    FileUtils.rm_f(Dir["#{artifacts_directory}/build_status = *"])
    FileUtils.touch(artifact("build_status = #{value}"))
    @status = value
  end

  def changeset
    File.read(artifact('changeset.log')) rescue ""
  end

  def output
    File.read(artifact('build.log')) rescue ""
  end
  
  def coverage_reports
    CoverageReportsRepository.new(artifacts_directory)
  end
  
  def formatted_time
    if time = @status.created_at
      time.strftime('%I:%M %p %b %d, %Y')
    else
      '-'
    end
  end

  def artifacts_directory
    @artifacts_dir ||= File.join(@project.path, "build-#{@label}")
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
    # Important note: --nosearch flag here prevents CC.rb from building itslef when a project has no Rakefile
    %{ruby -e "require 'rubygems' rescue nil; require 'rake'; load '#{File.expand_path(RAILS_ROOT)}/tasks/cc_build.rake'; ARGV << '--nosearch'#{Log.verbose? ? " << '--trace'" : ""} << 'cc:build'; Rake.application.run"}
  end

  def last
    builds = @project.builds
    builds.each_index do |i|
      if builds[i].label == label
        return i > 0 ? builds[i - 1] : nil
      end
    end
    nil
  end

  def in_clean_environment_on_local_copy(&block)
    old_rails_env = ENV['RAILS_ENV']
    # If we don't clean RAILS_ENV OS variable, tests of the project we are building would be 
    # executed under 'builder' Rails environment
    ENV.delete('RAILS_ENV')
    # set OS variable CC_BUILD_ARTIFACTS so that custom build tasks know where to redirect their products
    ENV['CC_BUILD_ARTIFACTS'] = self.artifacts_directory
    ENV['CC_RAKE_TASK'] = self.rake_task
    begin
      Dir.chdir(project.local_checkout, &block)
    ensure
      ENV['RAILS_ENV'] = old_rails_env
    end
  end

  private
  
  class CoverageReportsRepository
    def initialize(artifacts_directory)
      @artifacts_directory = artifacts_directory
    end

    def [](coverage_type)
      File.read("#{@artifacts_directory}/coverage-#{coverage_type}.log") rescue ""
    end
  end

  # TODO: Does it need to exist? Can't a Struct/OpenStruct be used instead of this class?
  # Don't know how to put this class to use Status...
  class NilBuild
    attr_reader :project, :label, :status, :time, :changeset, :output

    def initialize
      @project = nil
      @label = @time = @changeset = @output = '-'
      @status = :never_built
    end
    
    def formatted_time
      '-'
    end

    def successful?
      false
    end
  end

end
