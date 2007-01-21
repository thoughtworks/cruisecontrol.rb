require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../sandbox'

class EmailNotifierTest < Test::Unit::TestCase
  BUILD_LOG = <<-EOL
    blah blah blah
    something built
    tests passed / failed / etc
  EOL

  def setup
    @sandbox = Sandbox.new

    ActionMailer::Base.deliveries = []

    @project = Project.new("myproj", nil, nil)
    @project.path = @sandbox.root
    @build = Build.new(@project, 5)

    @notifier = @project.email_notifier
    @notifier.emails = ["jeremystellsmith@gmail.com", "jeremy@thoughtworks.com"]
  end
  
  def teardown
    @sandbox.clean_up
  end

  def test_do_nothing_with_passing_build
    @notifier.build_finished(@build)

    assert_equal [], ActionMailer::Base.deliveries
  end

  def test_send_email_with_failing_build
    @build.expects(:failed?).returns(true)
    @build.expects(:output).returns(BUILD_LOG)

    @notifier.build_finished(@build)

    mail = ActionMailer::Base.deliveries[0]

    assert_equal @notifier.emails, mail.to
    assert_equal "myproj Build 5 - FAILED", mail.subject
    assert_equal BUILD_LOG, mail.body
  end

  def test_send_email_with_fixed_build
    last_build = Build.new(@project, 4)
    last_build.expects(:failed?).returns(true)

    @build.expects(:last).returns(last_build)
    @build.expects(:output).returns(BUILD_LOG)

    @notifier.build_finished(@build)

    mail = ActionMailer::Base.deliveries[0]

    assert_equal @notifier.emails, mail.to
    assert_equal "myproj Build 5 - FIXED", mail.subject
    assert_equal BUILD_LOG, mail.body
  end
end