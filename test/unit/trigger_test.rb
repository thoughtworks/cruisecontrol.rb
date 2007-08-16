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
      trigger = SuccessfulBuildTrigger.new(one, :two)

      create_build one, 1
      create_build two, 1
      assert_equal [], trigger.revisions_to_build

      create_build two, 2, :fail!
      assert_equal [], trigger.revisions_to_build
      create_build two, 3
      assert_equal [Revision.new('3')], trigger.revisions_to_build
      
      create_build one, 3, :fail!
      assert_equal [], trigger.revisions_to_build

      create_build two, 4
      create_build two, 5
      create_build two, 6, :fail!
      assert_equal [Revision.new('5')], trigger.revisions_to_build
    end
  end
  
  def test_triggered_by__change_in_source_control
    with_sandbox_project do |sandbox, project|
      project.expects(:new_revisions).returns([Revision.new('5')])

      trigger = ChangeInSourceControlTrigger.new(project)

      assert_equal [Revision.new('5')], trigger.revisions_to_build
    end
  end

  def test_triggered_by__successful_rebuild_of_should_truncate_appended_build_label
    in_total_sandbox do |sandbox|
      Configuration.stubs(:projects_directory).returns(sandbox.root)
      one, two = sandbox.new_project('one'), sandbox.new_project('two')
      trigger = SuccessfulBuildTrigger.new(one, :two)

      create_build one, 1
      create_build two, 1
      assert_equal [], trigger.revisions_to_build

      create_build two, 2, :fail!
      assert_equal [], trigger.revisions_to_build
      create_build two, 3, :fail!
      create_build two, 3.1
      assert_equal [Revision.new('3')], trigger.revisions_to_build
    end
  end

  private

  def create_build(project, label, state = :succeed!)
    project.create_build(label).build_status.send(state, 0)
  end

end
