``# this module will create builds for testing
module BuildFactory

  # TODO Try to unify the ten thousand ways we use to create projects in tests
  def create_project(name)
    @sandbox.new :directory => "#{name}/work"
    project = Project.new(name, FakeSourceControl.new)
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

    @the_project = Project.new("the_project", FakeSourceControl.new)
    @the_project.path = "."
    @the_project
  end
end