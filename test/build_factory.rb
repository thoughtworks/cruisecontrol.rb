# this module will create builds for testing
module BuildFactory
  def create_project(name)
    @sandbox.new :directory => "#{name}/work"
    project = Project.new(name)
    project.path = name
    project
  end

  def create_build(label, status = :success)
    @sandbox.new :file => "build-#{label}/build_status.#{status}"
  end
  
  def create_builds(*labels)
    labels.each {|label| create_build(label) }
  end
  
  def the_project
    return @the_project if @the_project

    @the_project = Project.new("the_project")
    @the_project.path = "."
    @the_project
  end
end