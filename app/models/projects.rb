require 'fileutils'

class Projects

  class << self
    def load_all
      Projects.new(Configuration.projects_directory).load_all
    end

    def find(project_name)
      # TODO: sanitize project_name to prevent a query injection attack here
      path = File.join(Configuration.projects_directory, project_name)
      return nil unless File.directory?(path)
      load_project(path)
    end

    def load_project(dir)
      project = Project.read(dir, load_config = false)
      project.path = dir
      project
    end

  end
  
  def initialize(dir = Configuration.projects_directory)
    @dir = dir
    @list = []
  end

  def load_all
    @list = Dir["#{@dir}/*"].find_all {|child| File.directory?(child)}.
                             collect  {|child| Projects.load_project(child)}
    self
  end
  
  def <<(project)
    raise "project named #{project.name.inspect} already exists" if @list.include?(project)
    begin
      @list << project
      save_project(project)
      checkout_local_copy(project)  
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
    project.source_control.checkout work_dir
  end
  
  # delegate everything else to the underlying @list
  def method_missing(method, *args, &block)
    @list.send(method, *args, &block)
  end

end
