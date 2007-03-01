require File.dirname(__FILE__) + '/../test_helper'

class EmailNotifierTest < Test::Unit::TestCase
  include FileSandbox
  
  BUILD_LOG = <<-EOL
    blah blah blah
    something built
    tests passed / failed / etc
  EOL

  def setup
    setup_sandbox

    ActionMailer::Base.deliveries = []

    @project = Project.new("myproj")
    @project.path = @sandbox.root
    @build = Build.new(@project, 5)
    @previous_build = Build.new(@project, 4)
    @notifier = EmailNotifier.new
    @notifier.emails = ["jeremystellsmith@gmail.com", "jeremy@thoughtworks.com"]
    @project.add_plugin(@notifier)
  end
  
  def teardown
    teardown_sandbox
  end

  def test_do_nothing_with_passing_build
    @notifier.build_finished(@build)
    assert_equal [], ActionMailer::Base.deliveries
  end

  def test_send_email_with_failing_build
    @notifier.build_finished(failing_build)

    mail = ActionMailer::Base.deliveries[0]

    assert_equal @notifier.emails, mail.to
    assert_equal "myproj Build 5 - FAILED", mail.subject
    assert_equal BUILD_LOG, mail.body
  end

  def test_send_email_with_fixed_build
    @build.expects(:output).returns(BUILD_LOG)

    @notifier.build_fixed(@build, @previous_build)

    mail = ActionMailer::Base.deliveries[0]

    assert_equal @notifier.emails, mail.to
    assert_equal "myproj Build 5 - FIXED", mail.subject
    assert_equal BUILD_LOG, mail.body
  end
  
  def test_logging_on_send
    CruiseControl::Log.expects(:event).with("Sent e-mail to 4 people", :info)
    @notifier.emails = ['foo@happy.com', 'bar@feet.com', 'you@me.com', 'uncle@tom.com']
    @notifier.build_finished(failing_build)
    CruiseControl::Log.verify

    CruiseControl::Log.expects(:event).with("Sent e-mail to 1 person", :info)
    @notifier.emails = ['foo@happy.com']
    @notifier.build_finished(failing_build)
    CruiseControl::Log.verify

    CruiseControl::Log.expects(:event).never
    @notifier.emails = []
    @notifier.build_finished(failing_build)
  end
  
  def test_useful_errors
    ActionMailer::Base.smtp_settings = {:foo => 5}
    CruiseControl::Log.expects(:event).with("Error sending e-mail - current server settings are :\n  :foo = 5", :error)
    BuildMailer.expects(:deliver_build_failed).raises('something')
    
    @notifier.emails = ['foo@crapty.com']
    
    assert_raises('something') { @notifier.build_finished(failing_build) }
    CruiseControl::Log.verify
  end
  
  private
  
  def failing_build
    @build.stubs(:failed?).returns(true)
    @build.stubs(:output).returns(BUILD_LOG)
    @build
  end
end