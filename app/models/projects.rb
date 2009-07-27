# Projects represents a list of Project objects. It is used internally by Cruise to keep track of
# and instantiate all projects associated with this CC.rb instance.
class Projects
  
  # Create a new project list with the given CRUISE_DATA_ROOT, /projects by default.
  def initialize(dir = CRUISE_DATA_ROOT + "/projects")
    @dir = dir
    @list = []
  end

  # Load all projects associated with this CC.rb instance by iterating through 
  def load_all
    @list = Dir["#{@dir}/*"].find_all {|child| File.directory?(child)}.sort.
                             collect  {|child| Project.load_project(child)}
    self
  end
  
  def <<(project)
    raise "Project named #{project.name.inspect} already exists in #@dir" if @list.include?(project)
    begin
      @list << project
      save_project(project)
      checkout_local_copy(project)
      write_config_example(project)
      self
    rescue
      FileUtils.rm_rf "#{@dir}/#{project.name}"
      raise
    end
  end

  def save_project(project)
    project.path = File.join(@dir, project.name)
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

  # delegate everything else to the underlying @list
  def method_missing(method, *args, &block)
    @list.send(method, *args, &block)
  end

end
