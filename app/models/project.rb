# A Project represents a particular CI build of a particular codebase. An instance is created 
# each time a build is triggered and yielded back to be configured by cruise_config.rb.
class Project
  attr_reader :name, :plugins, :build_command, :rake_task, :config_tracker, :path, :settings, :config_file_content, :error_message
  attr_accessor :source_control, :scheduler
  
  class << self
    attr_accessor_with_default :plugin_names, []
    attr_accessor :current_project
    
    def all(dir=CRUISE_DATA_ROOT + "/projects")
      load_all(dir).map do |project_dir|
        load_project project_dir
      end
    end
    
    def create(project_name, scm, dir=CRUISE_DATA_ROOT + "/projects")
      returning(Project.new(project_name, scm)) do |project|
        raise "Project named #{project.name.inspect} already exists in #{dir}" if Project.all(dir).include?(project)
        begin
          save_project(project, dir)
          checkout_local_copy(project)
          write_config_example(project)
        rescue
          FileUtils.rm_rf "#{dir}/#{project.name}"
          raise
        end
      end
    end
    
    def plugin(plugin_name)
      self.plugin_names << plugin_name unless RAILS_ENV == 'test' or self.plugin_names.include? plugin_name
    end

    def read(dir, load_config = true)
      returning Project.new(File.basename(dir)) do |project|
        self.current_project = project
        project.load_config if load_config
      end
    ensure
      self.current_project = nil
    end

    def configure
      raise 'No project is currently being created' if current_project.nil?
      yield current_project
    end
    
    def find(project_name)
      # TODO: sanitize project_name to prevent a query injection attack here
      path = File.join(CRUISE_DATA_ROOT, 'projects', project_name)
      return nil unless File.directory?(path)
      load_project(path)
    end

    def load_project(dir)
      returning read(dir, load_config = false) do |project|
        project.path = dir
      end
    end
    
    private
    
      def load_all(dir)
        Dir["#{dir}/*"].find_all {|child| File.directory?(child)}.sort
      end
    
      def save_project(project, dir)
        project.path = File.join(dir, project.name)
        FileUtils.mkdir_p project.path
      end

      def checkout_local_copy(project)
        work_dir = File.join(project.path, 'work')
        FileUtils.mkdir_p work_dir
        project.source_control.checkout
      end

      def write_config_example(project)
        config_example = File.join(RAILS_ROOT, 'config', 'cruise_config.rb.example')
        config_in_subversion = File.join(project.path, 'work', 'cruise_config.rb')
        cruise_config = File.join(project.path, 'cruise_config.rb')
        if File.exists?(config_example) and not File.exists?(config_in_subversion)
          FileUtils.cp(config_example, cruise_config)
        end
      end
  end
  
  def initialize(name, scm = nil)
    @name = name
    @path = File.join(CRUISE_DATA_ROOT, 'projects', @name)
    @scheduler = PollingScheduler.new(self)
    @plugins = []
    @config_tracker = ProjectConfigTracker.new(self.path)
    @settings = ''
    @config_file_content = ''
    @error_message = ''
    @triggers = [ChangeInSourceControlTrigger.new(self)]
    self.source_control = scm if scm
    instantiate_plugins
  end
  
  def source_control=(scm_adapter)
    scm_adapter.path = local_checkout
    @source_control = scm_adapter
  end

  def source_control
    @source_control || self.source_control = SourceControl.detect(local_checkout)
  end

  def load_and_remember(file)
    return unless File.file?(file)
    @settings << File.read(file) << "\n"
    @config_file_content = @settings
    load file
  end

  def load_config
    begin
      retried_after_update = false
      begin
        load_and_remember config_tracker.central_config_file
      rescue Exception 
        if retried_after_update
          raise
        else
          source_control.update
          retried_after_update = true
          retry
        end
      end
      load_and_remember config_tracker.local_config_file
    rescue Exception => e
      @error_message = "Could not load project configuration: #{e.message} in #{e.backtrace.first}"
      CruiseControl::Log.event(@error_message, :fatal) rescue nil
      @settings = ""
    end
    self
  end

  def path=(value)
    value = File.expand_path(value)
    @config_tracker = ProjectConfigTracker.new(value)
    @path = value
    @source_control.path = local_checkout if @source_control
    @path
  end

  def instantiate_plugins
    self.class.plugin_names.each do |plugin_name|
      plugin_instance = plugin_name.to_s.camelize.constantize.new(self)
      self.add_plugin(plugin_instance)
    end
  end

  def add_plugin(plugin, plugin_name = plugin.class)
    @plugins << plugin
    plugin_name = plugin_name.to_s.underscore.to_sym
    if self.respond_to?(plugin_name)
      raise "Cannot register an plugin with name #{plugin_name.inspect} " +
            "because another plugin, or a method with the same name already exists"
    end
    self.metaclass.send(:define_method, plugin_name) { plugin }
    plugin
  end

  def ==(another)
    another.is_a?(Project) and another.name == self.name
  end
  
  def config_valid?
    @settings == @config_file_content
  end

  def build_command=(value)
    raise 'Cannot set build_command when rake_task is already defined' if value and @rake_task
    @build_command = value
  end

  def rake_task=(value)
    raise 'Cannot set rake_task when build_command is already defined' if value and @build_command
    @rake_task = value
  end

  def local_checkout
    File.join(@path, 'work')
  end

  def builds
    raise "Project #{name.inspect} has no path" unless path

    the_builds = Dir["#{path}/build-*"].collect do |build_dir|
      build_directory = File.basename(build_dir)
      build_label = build_directory.split("-")[1]
      Build.new(self, build_label)
    end
    order_by_label(the_builds)
  end

  def builder_state_and_activity
    BuilderStatus.new(self).status
  end 
  
  def builder_error_message
    BuilderStatus.new(self).error_message
  end
  
  def last_build
    builds.last
  end
  
  def create_build(label)
    Build.new(self, label, true)
  end
  
  def previous_build(current_build)  
    all_builds = builds
    index = get_build_index(all_builds, current_build.label)
    
    if index > 0
      return all_builds[index-1]
    else  
      return nil
    end
  end
  
  def next_build(current_build)
    all_builds = builds
    index = get_build_index(all_builds, current_build.label)

    if index == (all_builds.size - 1)
      return nil
    else
      return all_builds[index + 1]
    end
  end
  
  def last_complete_build
    builds.reverse.find { |build| !build.incomplete? }
  end

  def find_build(label)
    # this could be optimized a lot
    builds.find { |build| build.label == label }
  end
    
  def last_complete_build_status
    return "failed" if BuilderStatus.new(self).fatal?
    previously_built? ? last_complete_build.status : 'never_built'
  end
  
  def previously_built?
    not last_complete_build.nil?
  end

  # TODO this and last_builds methods are not Project methods, really - they can be inlined somewhere in the controller layer
  def last_five_builds
    last_builds(5)
  end
  
  def last_builds(n)
    result = builds.reverse[0..(n-1)]
  end

  def build_if_necessary
    begin
      if build_necessary?(reasons = [])
        remove_build_requested_flag_file if build_requested?
        return build(source_control.latest_revision, reasons)
      else
        return nil
      end
    rescue => e
      unless e.message.include? "No commit found in the repository."
        notify(:build_loop_failed, e) rescue nil
        @build_loop_failed = true
        raise
      end 
    ensure
      notify(:sleeping) unless @build_loop_failed rescue nil
    end
  end

  #todo - test
  def build_necessary?(reasons)
    if builds.empty?
      reasons << "This is the first build"
      true
    else 
      @triggers.any? {|t| t.build_necessary?(reasons) }
    end
  end
  
  def build_requested?
    File.file?(build_requested_flag_file)
  end
  
  def request_build
    if builder_state_and_activity == 'builder_down'
      BuilderStarter.begin_builder(name)
      10.times do
        sleep 1.second.to_i
        break if builder_state_and_activity != 'builder_down' 
      end
    end
    unless build_requested?
      notify :build_requested
      create_build_requested_flag_file
    end
  end
  
  def config_modified?
    if config_tracker.config_modified?
      notify :configuration_modified
      true
    else
      false
    end
  end
  
  def build_if_requested
    if build_requested?
      remove_build_requested_flag_file
      build(source_control.latest_revision, ['Build was manually requested.', source_control.latest_revision.to_s])
    end
  end
  
  def force_build(message = 'Build was forced')
    build(source_control.latest_revision, [message, source_control.latest_revision.to_s])
  end
  
  def update_project_to_revision(build, revision)
    if do_clean_checkout?
      File.open(build.artifact('source_control.log'), 'w') do |f| 
        start = Time.now
        f << "checking out build #{build.label}, this could take a while...\n"
        source_control.clean_checkout(revision, f)
        f << "\ntook #{Time.now - start} seconds"
      end
    else
      source_control.update(revision)
    end
  end
  
  def build(revision = source_control.latest_revision, reasons = [])
    if Configuration.serialize_builds
      BuildSerializer.serialize(self) { build_without_serialization(revision, reasons) }
    else
      build_without_serialization(revision, reasons)
    end
  end
        
  def build_without_serialization(revision, reasons)
    return if revision.nil? # this will only happen in the case that there are no revisions yet

    notify(:build_initiated)
    previous_build = last_build    
    
    build = Build.new(self, create_build_label(revision.number), true)
    
    begin
      log_changeset(build.artifacts_directory, reasons)
      update_project_to_revision(build, revision)

      if config_modified?
        build.abort
        throw :reload_project
      end
    
      notify(:build_started, build)
      build.run
      notify(:build_finished, build)
    rescue => e
      build.fail!(e.message)
      raise
    end

    if previous_build
      if build.failed? and previous_build.successful?
        notify(:build_broken, build, previous_build)
      elsif build.successful? and previous_build.failed?
        notify(:build_fixed, build, previous_build)
      end
    end

    build
  end

  def notify(event, *event_parameters)
    unless BuilderPlugin.known_event? event
      raise "You attempted to notify the project of the #{event} event, but the plugin architecture does not understand this event. Add a method to BuilderPlugin, and document it."
    end
    
    errors = []
    results = @plugins.collect do |plugin| 
      begin
        plugin.send(event, *event_parameters) if plugin.respond_to? event
      rescue => plugin_error
        CruiseControl::Log.error(plugin_error)
        if (event_parameters.first and event_parameters.first.respond_to? :artifacts_directory)
          plugin_errors_log = File.join(event_parameters.first.artifacts_directory, 'plugin_errors.log')
          begin
            File.open(plugin_errors_log, 'a') do |f|
              f << "#{plugin_error.message} at #{plugin_error.backtrace.first}"
            end
          rescue => e
            CruiseControl::Log.error(e)
          end
        end
        errors << "#{plugin.class}: #{plugin_error.message}"
      end
    end
    
    if errors.empty?
      return results.compact
    else
      if errors.size == 1
        error_message = "Error in plugin #{errors.first}"
      else
        error_message = "Errors in plugins:\n" + errors.map { |e| "  #{e}" }.join("\n")
      end
      raise error_message
    end
  end
  
  def log_changeset(artifacts_directory, reasons)
    File.open(File.join(artifacts_directory, 'changeset.log'), 'w') do |f|
      reasons.each { |reason| f << reason.to_s << "\n" }
    end
  end

  def build_requested_flag_file
    File.join(path, 'build_requested')
  end

  def to_param
    self.name
  end
  
  # possible values for this is :never, :always, :every => 1.hour, :every => 2.days, etc
  def do_clean_checkout(how_often = :always)
    unless how_often == :always || how_often == :never || (how_often[:every].is_a?(Integer))
      raise "expected :never, :always, :every => 1.hour, :every => 2.days, etc"
    end
    @clean_checkout_when = how_often
  end
  
  def do_clean_checkout?
    case @clean_checkout_when
    when :always then true
    when nil, :never then false
    else
      timestamp_filename = File.join(self.path, 'last_clean_checkout_timestamp')
      unless File.exist?(timestamp_filename)
        save_timestamp(timestamp_filename)
        return true
      end

      time_since_last_clean_checkout = Time.now - load_timestamp(timestamp_filename)
      if time_since_last_clean_checkout > @clean_checkout_when[:every]
        save_timestamp(timestamp_filename)
        true
      else
        false
      end
    end
  end

  def save_timestamp(file)
    File.open(file, 'w') { |f| f.write Time.now.gmtime.strftime("%Y-%m-%d %H:%M:%SZ") }
  end

  def load_timestamp(file)
    Time.parse(File.read(file))
  end

  def triggered_by(*new_triggers)
    @triggers += new_triggers

    @triggers.map! do |trigger|
      if trigger.is_a?(String) || trigger.is_a?(Symbol)
        SuccessfulBuildTrigger.new(self, trigger)
      else
        trigger
      end
    end
    @triggers
  end

  def triggered_by=(triggers)
    @triggers = [triggers].flatten
  end
  
  private
  
  # sorts a array of builds in order of revision number and rebuild number 
  def order_by_label(builds)
    if source_control.creates_ordered_build_labels?
      builds.sort_by do |build|
        number, rebuild = build.label.split('.')
        # when a label only has build number, rebuild = nil, nil.to_i = 0, and this code still works
        [number.to_i, rebuild.to_i]
      end
    else
      builds.sort_by(&:time)
    end
  end
    
  def create_build_label(revision_number)
    revision_number = revision_number.to_s
    build_labels = builds.map { |b| b.label }
    related_builds_pattern = Regexp.new("^#{Regexp.escape(revision_number)}(\\.\\d+)?$")
    related_builds = build_labels.select { |label| label =~ related_builds_pattern }

    case related_builds
    when [] then revision_number
    when [revision_number] then "#{revision_number}.1"
    else
      rebuild_numbers = related_builds.map { |label| label.split('.')[1] }.compact
      last_rebuild_number = rebuild_numbers.sort_by { |x| x.to_i }.last 
      "#{revision_number}.#{last_rebuild_number.next}"
    end
  end
  
  def create_build_requested_flag_file
    FileUtils.touch(build_requested_flag_file)
  end

  def remove_build_requested_flag_file
    FileUtils.rm_f(Dir[build_requested_flag_file])
  end
  
  def get_build_index(all_builds, build_label)
    result = 0;
    all_builds.each_with_index {|build, index| result = index if build.label == build_label}
    result 
  end
  
end