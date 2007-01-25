require 'fileutils'

class Projects

  class << self
    def load_all(dir = Configuration.builds_directory)
      Projects.new(dir).load_all
    end

    def load_project(dir)
      project = Project.load_or_create(dir)
      project.path = dir
      project
    end
  end
  
  def initialize(dir = Configuration.builds_directory)
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
    @list << project
    save_project(project)

    work_dir = "#{@dir}/#{project.name}/work"
    FileUtils.mkdir_p work_dir
    project.source_control.checkout work_dir
    
    self
  rescue
    FileUtils.rm_rf "#{@dir}/#{project.name}"
    raise
  end

  def save_project(project)
    path = @dir + "/" + project.name
    FileUtils::makedirs path
    File.open(path + "/project_config.rb", "w") {|f| f << project.memento}
  end

  # delegate everything else to the underlying @list
  def method_missing(method, *args, &block)
    @list.send(method, *args, &block)
  end

end
