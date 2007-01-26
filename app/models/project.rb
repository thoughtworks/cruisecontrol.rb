require 'fileutils'

class Project
  @@plugin_names = []

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
  attr_accessor :source_control, :path, :local_checkout, :scheduler

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
  end

  def url_name
    name.downcase.gsub(/[^a-z0-9]/, '')
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
    raise "Project #{name.inspect} has no path" unless @path

    Dir["#{@path}/build-*/build_status = *"].collect do |status_file|
      dir = File.dirname(status_file)
      number = File.basename(dir)[6..-1].to_i

      Build.new(self, number)
    end.sort_by { |build| build.label }
  end

  def last_build
    builds.last || Build.nil
  end

  def memento
    mementos = [source_control.memento, scheduler.memento]
    mementos << "project.rake_task = #{@rake_task.inspect}" if @rake_task
    mementos << "project.build_command = #{@build_command.inspect}" if @build_command
    
    mementos += notify(:memento)
    
    return '' if mementos.compact.empty?

    <<-EOL
Project.configure do |project|
  #{mementos.compact.join("\n").gsub(/\n/, "\n  ")}
end
    EOL
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

  def build(revisions = [@source_control.latest_revision(self)])
    last_revision = revisions.last
    build = Build.new(self, last_revision.number)
    log_changeset(build.artifacts_directory, revisions)
    @source_control.update(self, last_revision)
    notify(:build_started, build)
    build.run
    notify(:build_finished, build)
    build
  end

  def notify(event, *event_parameters)
    @plugins.each do |plugin|
      plugin.send(event, *event_parameters) if plugin.respond_to?(event)
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

  def notify(sym, *args)
    @plugins.collect do |plugin|
      plugin.send(sym, *args) if plugin.respond_to?(sym)
    end.compact
  end

end

unless RAILS_ENV == 'test'
  plugins = Dir[File.join(RAILS_ROOT, 'builder_plugins', 'installed', '*.rb')]
  plugins.each do |plugin|
    if RAILS_ENV == 'development'
      load plugin
    else
      plugin_name_without_extension = File.basename(plugin)[0..-4]
      require plugin_name_without_extension
    end
  end
end
