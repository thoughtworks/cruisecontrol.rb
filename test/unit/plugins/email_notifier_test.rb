require 'test_helper'

class EmailNotifierTest < ActiveSupport::TestCase
  include FileSandbox

  BUILD_LOG = <<-EOL
    blah blah blah
    something built
    tests passed / failed / etc
    <this should be plain text & should not be escaped>
  EOL

  setup do
    setup_sandbox

    ActionMailer::Base.deliveries = []

    @project = Project.new(:name => "myproj")
    @project.path = @sandbox.root
    @build = Build.new(@project, 5)
    @previous_build = Build.new(@project, 4)

    @notifier = EmailNotifier.new
    @notifier.emails = ["default@gmail.com", "ccrb@thoughtworks.com"]
    @notifier.from = 'cruisecontrol@thoughtworks.com'

    @project.add_plugin(@notifier, :test_email_notifier)
  end

  teardown do
    teardown_sandbox
  end

  context "#build_finished" do
    test "should not send an email for a passing build" do
      @notifier.build_finished(@build)
      assert_equal [], ActionMailer::Base.deliveries
    end

    test "should send an email if the build fails" do
      @notifier.build_finished(failing_build)

      mail = ActionMailer::Base.deliveries[0]

      assert_equal @notifier.emails, mail.to
      assert_equal "[CruiseControl] myproj build 5 failed", mail.subject
    end

    test "should send an email for a passing build that fixes a failing build" do
      Configuration.stubs(:dashboard_url).returns(nil)
      @build.expects(:output).at_least_once.returns(BUILD_LOG)

      @notifier.build_fixed(@build, @previous_build)

      mail = ActionMailer::Base.deliveries[0]

      assert_equal @notifier.emails, mail.to
      assert_equal "[CruiseControl] myproj build 5 fixed", mail.subject
    end

    test "should not log any sent emails if none are sent" do
      CruiseControl::Log.expects(:event).never
      BuildMailer.expects(:build_report).never
      @notifier.emails = []
      @notifier.build_finished(failing_build)
    end

    test "should log a single recipient if an email is sent" do
      CruiseControl::Log.expects(:event).with("Sent e-mail to 1 person", :debug)
      BuildMailer.expects(:build_report).returns mock(:deliver => true)
      @notifier.emails = ['foo@happy.com']
      @notifier.build_finished(failing_build)
    end

    test "should log multiple recipients if multiple emails are sent" do
      CruiseControl::Log.expects(:event).with("Sent e-mail to 4 people", :debug)
      BuildMailer.expects(:build_report).returns mock(:deliver => true)
      @notifier.emails = ['foo@happy.com', 'bar@feet.com', 'you@me.com', 'uncle@tom.com']
      @notifier.build_finished(failing_build)
    end

    test "should log current ActionMailer settings if delivery fails" do
      ActionMailer::Base.stubs(:smtp_settings).returns(:foo => 5)
      CruiseControl::Log.expects(:event).with("Error sending e-mail - current server settings are :\n  :foo = 5", :error)
      mock_mail = mock("Email")
      mock_mail.expects(:deliver).raises('oh noes!')

      BuildMailer.expects(:build_report).returns mock_mail

      @notifier.emails = ['foo@crapty.com']

      assert_raise_with_message(RuntimeError, 'oh noes!') do
        @notifier.build_finished(failing_build)
      end
    end

    test "should use the default email recipients when explicit recipients are not specified" do
      Configuration.expects(:email_from).returns('central@foo.com')
      @notifier.from = nil
      build = failing_build()

      BuildMailer.expects(:build_report).with(build, ['default@gmail.com', 'ccrb@thoughtworks.com'],
                          'central@foo.com', 'myproj build 5 failed', 'The build failed.').returns mock(:deliver => true)

      @notifier.build_finished(failing_build)
    end

    test "should provide the URL of the build in the notification email" do
      Configuration.stubs(:dashboard_url).returns("http://www.my.com")
      @notifier.emails = ['foo@happy.com']
      @notifier.build_finished(failing_build)

      mail = ActionMailer::Base.deliveries[0]
      assert_match /http:\/\/www.my.com\/builds\/myproj\/5/, mail.body.to_s
    end

    test "should list the build info in the notification email if the dashboard url is not set" do
      Configuration.stubs(:dashboard_url).returns(nil)
      @notifier.emails = ['foo@happy.com']
      @notifier.build_finished(failing_build)

      mail = ActionMailer::Base.deliveries[0]
      assert_match /Note: if you set Configuration\.dashboard_url in site_config\.rb/, mail.body.to_s
    end

    test "should contain unescaped build output in the notification email if the dashboard url is not set" do
      Configuration.stubs(:dashboard_url).returns(nil)
      @notifier.emails = ['foo@happy.com']
      @notifier.build_finished(failing_build)

      mail = ActionMailer::Base.deliveries[0]
      assert_match /<this should be plain text & should not be escaped>/, mail.body.to_s
    end
  end

  private

  def failing_build
    @build.stubs(:failed?).returns(true)
    @build.stubs(:output).returns(BUILD_LOG)
    @build
  end
end
