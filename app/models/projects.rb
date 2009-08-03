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
  
  # delegate everything else to the underlying @list
  def method_missing(method, *args, &block)
    @list.send(method, *args, &block)
  end

end
