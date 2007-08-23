require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SuccessfulBuildTriggerTest < Test::Unit::TestCase
  include FileSandbox

  def test_revisions_to_build
    in_total_sandbox do |sandbox|
      Configuration.stubs(:projects_directory).returns(sandbox.root)
      one = create_project(sandbox, 'one')
      two = create_project(sandbox, 'two')

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

  def test_revisions_to_build_should_truncate_appended_build_label
    in_total_sandbox do |sandbox|
      Configuration.stubs(:projects_directory).returns(sandbox.root)
      one = create_project(sandbox, 'one')
      two = create_project(sandbox, 'two')

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

  def create_project(sandbox, name)
    sandbox.new :directory => "#{name}/work"
    Project.new(name)
  end

end

