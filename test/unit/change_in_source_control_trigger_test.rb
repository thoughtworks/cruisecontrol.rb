require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class ChangeInSourceControlTriggerTest < Test::Unit::TestCase
  include FileSandbox

  def test_build_necessary
    with_sandbox_project do |sandbox, project|
      project.source_control.expects(:up_to_date?).with{|reasons| reasons << [Revision.new('5')]}.returns(false)

      project.add_plugin listener = Object.new
      listener.expects(:new_revisions_detected).with([Revision.new('5')])

      trigger = ChangeInSourceControlTrigger.new(project)

      assert_equal true, trigger.build_necessary?(reasons = [])
      assert_equal [[Revision.new('5')]], reasons
    end
  end

  def test_build_not_necessary
    with_sandbox_project do |sandbox, project|
      project.source_control.expects(:up_to_date?).returns(true)

      project.add_plugin listener = Object.new
      listener.expects(:no_new_revisions_detected)

      trigger = ChangeInSourceControlTrigger.new(project)

      assert_equal false, trigger.build_necessary?(reasons = [])
    end
  end
end
