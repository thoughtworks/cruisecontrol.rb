require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'project'

class FileSandbox::Sandbox
  def new_project(name)
    new :directory => "#{name}/work"
    Project.new(name)
  end
end

class TriggerTest < Test::Unit::TestCase
  include FileSandbox
  
  # 1. fire build when successful build happens in other project
  # 2. store last build # of last project...where? - could depend on multiple projects
  # 3. update ourselves to other project version _iff_ in the same repo
  # 4. otherwise update ourselves to head
  def test_triggered_by__successful_build_of
    in_total_sandbox do |sandbox|
      Configuration.stubs(:projects_directory).returns(sandbox.root)
      one, two = sandbox.new_project('one'), sandbox.new_project('two')
      trigger = SuccessfulBuildTrigger.new(:two)

      create_build one, 1
      create_build two, 1
      assert_equal [], trigger.get_revisions_to_build(one)

      create_build two, 2, :fail!
      assert_equal [], trigger.get_revisions_to_build(one)
      create_build two, 3
      assert_equal [Revision.new('3')], trigger.get_revisions_to_build(one)
      
      create_build one, 3, :fail!
      assert_equal [], trigger.get_revisions_to_build(one)

      create_build two, 4
      create_build two, 5
      create_build two, 6, :fail!
      assert_equal [Revision.new('5')], trigger.get_revisions_to_build(one)      
    end
  end
  
  def test_triggered_by__change_in_source_control
    with_sandbox_project do |sandbox, project|
      project.expects(:new_revisions).returns(5)

      trigger = ChangeInSourceControlTrigger.new

      assert_equal 5, trigger.get_revisions_to_build(project)
    end
  end
  
  def test_triggered_by__change_in_svn_external
  end
  
  def test_project_triggered_by
    p = Project.new('foo')
    def p.trigger
      @trigger
    end
    
    assert_equal ChangeInSourceControlTrigger, p.trigger.class
    
    p.triggered_by 'CruiseControl-Fast'
    assert_equal SuccessfulBuildTrigger.new('CruiseControl-Fast'), p.trigger
    
    p.triggered_by :ccrb
    assert_equal SuccessfulBuildTrigger.new(:ccrb), p.trigger
  end
   
  private
  
  def create_build(project, label, state = :succeed!)
    project.create_build(label).build_status.send(state, 0)
  end
end
