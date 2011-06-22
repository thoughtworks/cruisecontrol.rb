require 'test_helper'

class ChangeInSourceControlTriggerTest < ActiveSupport::TestCase
  include FileSandbox
  include SourceControl

  context "#build_necessary?" do
    test "should be true if there is a new revision in the list of reasons" do
      with_sandbox_project do |sandbox, project|
        project.source_control.expects(:up_to_date?).with do |reasons|
          reasons << Subversion::Revision.new('5')
        end.returns(false)

        project.add_plugin listener = Object.new
        listener.expects(:new_revisions_detected).with([Subversion::Revision.new('5')])

        trigger = ChangeInSourceControlTrigger.new(project)

        assert_equal true, trigger.build_necessary?(reasons = [])
        assert_equal [ Subversion::Revision.new('5') ], reasons
      end
    end

    test "should be false if there are no new revisions detected" do
      with_sandbox_project do |sandbox, project|
        project.source_control.expects(:up_to_date?).returns(true)

        project.add_plugin listener = Object.new
        listener.expects(:no_new_revisions_detected)

        trigger = ChangeInSourceControlTrigger.new(project)

        assert_equal false, trigger.build_necessary?(reasons = [])
      end
    end
  end
end
