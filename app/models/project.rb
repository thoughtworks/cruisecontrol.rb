require 'fileutils'

class Project
  @@plugin_names = []
  ForceBuildTagFileName = "force_build_requested"

  def self.plugin(plugin_name)
    unless RAILS_ENV == 'test'
      @@plugin_names << plugin_name unless @@plugin_names.include? plugin_name
    end
  end

  def self.load_or_create(dir)
    config_file = File.expand_path(File.join(dir, 'project_config.rb'))
    project = @project = Project.new(File.basename(dir), Subversion.new, dir + "/work")
    project.path = dir
    begin
      load config_file if File.exists? config_file
      return project
    rescue => e
      raise "Could not load #{config_file} : #{e.message} in #{e.backtrace.first}"
    ensure
      @project = nil
    end
  end

  def self.configure
    raise "No project is currently being created" unless @project
    yield @project
  end

  attr_reader :name, :plugins, :build_command, :rake_task
  attr_accessor :source_control, :path, :local_checkout, :scheduler, :builder_status

  def initialize(name, source_control = Subversion.new, local_checkout = nil)
    @name, @source_control, @local_checkout = name, source_control, local_checkout
    @path = File.join(Configuration.builds_directory, @name)
    @plugins = []
    @plugins_by_name = {}
    @@plugin_names.each do |plugin_name|
      plugin_instance = plugin_name.to_s.camelize.constantize.new(self)
      self.add_plugin(plugin_instance)
    end
    @scheduler = PollingScheduler.new(self)    
    @builder_status = ProjectBuilderStatus.new(path)
    # TODO: Not sure if we should exclude this like so or mock it out for testing? (Joe/Arty)
    unless RAILS_ENV == 'test'
      add_plugin @builder_status
    end
  end

  #used by rjs to refresh project if build state tag changed.
  def builder_and_build_states_tag    
    builder_state_and_activity.gsub(' ', '') + (builds.empty? ? '' : last_build.label.to_s) + last_build_status.to_s
  end
  
  def ==(another)
    another.is_a?(Project) and another.name == self.name
  end

  def build_command=(value)
    raise 'Cannot set build_command when rake_task is already defined' if value and @rake_task
    @build_command = value
  end

  def rake_task=(value)
    raise 'Cannot set rake_task when build_command is already defined' if value and @build_command
    @rake_task = value
  end

  def builds
    raise "Project #{name.inspect} has no path" unless path

    Dir["#{path}/build-*/build_status.*"].collect do |status_file|
      dir = File.dirname(status_file)
      number = File.basename(dir)[6..-1].to_f

      Build.new(self, number)
    end.sort_by { |build| build.label }
  end

  def builder_state       
    ProjectBlocker.blocked?(self) ? Status::RUNNING : Status::NOT_RUNNING
  end
  
  def builder_activity
    state = builder_state
    state == Status::RUNNING ? @builder_status.status : state
  end
  
  def builder_state_and_activity
    result = builder_state.downcase
    result += " (#{builder_activity.to_s})" if (builder_state == Status::RUNNING)
    result
  end 
  
  def last_build
    builds.last
  end
  
  def last_build_status
    builds.empty? ? :never_built : last_build.status
  end

  def last_five_builds
    builds.reverse[0..4]
  end

  def build_if_necessary
    notify(:polling_source_control)
    begin
      revisions = new_revisions()
      if revisions.empty?
        notify(:no_new_revisions_detected)
        return nil
      else
        notify(:new_revisions_detected, revisions)
        return build(revisions)
      end
    rescue => e
      notify(:build_loop_failed, e) rescue nil
      raise
    ensure
      notify(:sleeping) rescue nil
    end
  end

  def new_revisions
    b = builds
    if b.empty?
      [@source_control.latest_revision(self)]
    else
      @source_control.revisions_since(self, b.last.label.to_i)
    end
  end
  
  def force_build_requested?
    File.file?(force_tag_file_name)
  end
  
  def request_force_build()
    result = ""
    begin
      ForceBuildBlocker.block(self)
      if ! force_build_requested?
        touch_force_tag_file 
        result = "The force build is pending now!"  
      else
        result =  "Another build is pending already!"     
      end
    rescue => lock_error
      result =  "Another build is pending already!"     
    ensure 
      ForceBuildBlocker.release(self) rescue nil
    end
    return result
  end
  
  def force_build_if_requested
    return if !force_build_requested?
    begin
      ForceBuildBlocker.block(self)
      comment = File.read(force_tag_file_name)
      build
      remove_force_tag_file
    rescue => error
      # FIXME and do what with it?
    ensure 
      ForceBuildBlocker.release(self) rescue nil
    end      
  end
  
  def force_build_request_allowed?
    builder_activity.to_s == "sleeping" and !force_build_requested?
  end

  def build(revisions = [@source_control.latest_revision(self)])   
    last_revision = revisions.last
    build = Build.new(self, validate_build_label(last_revision.number))
    log_changeset(build.artifacts_directory, revisions)
    @source_control.update(self, last_revision)
    notify(:build_started, build)
    build.run
    notify(:build_finished, build)
    build    
  end

  def notify(event, *event_parameters)
    errors = []
    results = @plugins.collect do |plugin| 
      begin
        plugin.send(event, *event_parameters) if plugin.respond_to?(event)
      rescue => plugin_error
        CruiseControl::Log.error(plugin_error)
        errors << "#{plugin.class}: #{plugin_error.message}"
      end
    end
    
    if errors.empty?
      return results.compact
    else
      if errors.size == 1
        error_message = "Plugin error: #{errors.first}"
      else
        error_message = "Plugin error:\n" + errors.map { |e| "  #{e}" }.join("\n")
      end
      raise error_message
    end
  end
  
  def log_changeset(artifacts_directory, revisions)
    File.open(File.join(artifacts_directory, 'changeset.log'), 'w') do |f|
      revisions.each { |rev| f << rev.to_s << "\n" }
    end
  end

  def add_plugin(plugin, plugin_name = plugin.class)
    @plugins << plugin
    plugin_name = plugin_name.to_s.underscore.to_sym
    if self.respond_to?(plugin_name)
      raise "Cannot register an plugin with name #{plugin_name.inspect} " +
            "because another plugin, or a method with the same name already exists"
    end
    @plugins_by_name[plugin_name] = plugin
    plugin
  end

  # access plugins by their names
  def method_missing(method_name, *args, &block)
    @plugins_by_name.key?(method_name) ? @plugins_by_name[method_name] : super
  end
  
  def respond_to?(method_name)
    @plugins_by_name.key?(method_name) or super
  end

  private
  
  def validate_build_label(label)
    existing_build = builds.find { |build| build.label == label}
    if( existing_build.nil?)
      label
    else
      validate_build_label(increment_label(label))
    end
  end
  
  def increment_label(label)
    ( label.to_i.to_s + '.' + (label.to_f.to_s.split('.')[1].to_i + 1).to_s ).to_f
  end

  def remove_force_tag_file
    FileUtils.rm_f(Dir[force_tag_file_name])
  end
    
  def touch_force_tag_file 
    FileUtils.touch(force_tag_file_name)   
  end
    
  def force_tag_file_name
    File.join(path,Project::ForceBuildTagFileName)
  end

end

# TODO make me pretty, move me to another file, invoke me from environment.rb
# TODO consider using Rails autoloading mechanism
# TODO what to do when plugin initializer raises an error?

plugin_loader = Object.new

def plugin_loader.load_plugin(plugin_path)
  plugin_name = File.basename(plugin_path).sub(/\.rb$/, '')
  CruiseControl::Log.debug("Loading plugin #{plugin_name}")
  if RAILS_ENV == 'development'
    load plugin_path
  else
    #convert path to something like 'my_plugin/init'
    require_path = plugin_name == 'init' ? File.basename(File.dirname(plugin_path)) + '/' + plugin_name : plugin_name
    require require_path
  end
end

def plugin_loader.load_all
  plugins = Dir[File.join(RAILS_ROOT, 'builder_plugins', 'installed', '*')]

  plugins.each do |plugin|
    if File.file?(plugin)
      if plugin[-3..-1] == '.rb' 
        load_plugin(File.basename(plugin))
      else
        # a file without .rb extension, ignore
      end
    elsif File.directory?(plugin)
      # ignore Subversion directory (although it should be considered hidden by Dir[], but just in case)
      next if plugin[-4..-1] == '.svn'
      init_path = File.join(plugin, 'init.rb')
      if File.file?(init_path)
        load_plugin(init_path)
      else
        log.error("No init.rb found in plugin directory #{plugin}")
      end
    else 
      # a path is neither file nor directory. whatever else it may be, let's ignore it.
      # TODO: find out what happens with symlinks on a Linux here? how about broken symlinks?
    end
  end
  
end

plugin_loader.load_all unless RAILS_ENV == 'test'
