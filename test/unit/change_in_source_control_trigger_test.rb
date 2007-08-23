require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ChangeInSourceControlTriggerTest < Test::Unit::TestCase
  include FileSandbox

  def test_revisions_to_build
    with_sandbox_project do |sandbox, project|
      project.expects(:new_revisions).returns([Revision.new('5')])

      trigger = ChangeInSourceControlTrigger.new(project)

      assert_equal [Revision.new('5')], trigger.revisions_to_build
    end
  end

end
