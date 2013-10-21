require 'test_helper'

class BuildMailerTest < ActionMailer::TestCase
  include FileSandbox

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  # TODO The old tests utilized deprecated APIs. Also, they made no sense. Rewrite.
  def test_build_report
      assert ActionMailer::Base.deliveries.count == 0
      with_sandbox_project do |sandbox, project|
        build = Build.new(project, 123, true)        
        recipients = ["test@test.com"]
        from = "from@example.com"
        subject = "#{build.project.name} build #{build.abbreviated_label} failed"
        message = "The build failed"
        BuildMailer.build_report(build, recipients, from, subject, message).deliver
        assert ActionMailer::Base.deliveries.count == 1
      end
  end

  # This test depends on a local smtp server to test actual sending over SMTP
  # Not sure how to test this without that dependency...
  # However, the reason I wrote this was because there were errors when actually sending emails via SMTP
  # because of bad header usage, but this test still doesn't catch that presumably due to MailCatcher(local SMPT server)
  # not caring about headers, whereas Amazon SES does.
  # def test_sending_build_report_over_smtp
  #   old_delivery_method,  old_smtp_settings = ActionMailer::Base.delivery_method, ActionMailer::Base.smtp_settings
  #   ActionMailer::Base.delivery_method = :smtp
  #   ActionMailer::Base.smtp_settings = { :address => "localhost", :port => 1025 } 
  #   assert ActionMailer::Base.deliveries.count == 0

  #   with_sandbox_project do |sandbox, project|
  #     build = Build.new(project, 123, true)        
  #     recipients = ["test@test.com"]
  #     from = "from@example.com"
  #     subject = "#{build.project.name} build #{build.abbreviated_label} failed"
  #     message = "The build failed"
  #     result = BuildMailer.build_report(build, recipients, from, subject, message).deliver
  #   end

  #   ActionMailer::Base.delivery_method = old_delivery_method
  #   ActionMailer::Base.smtp_settings = old_smtp_settings
  # end
end
