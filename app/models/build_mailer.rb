class BuildMailer < ActionMailer::Base

  def build_report(build, recipients, subject, message, sent_at = Time.now)
    @subject    = "[CruiseControl] #{subject}"
    @body       = {:build => build, :message => message}
    @recipients = recipients
    @from       = 'cruisecontrol@thoughtworks.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def test(recipients, sent_at = Time.now)
    @subject    = 'Test CI E-mail'
    @body       = {}
    @recipients = recipients
    @from       = 'cruisecontrol@thoughtworks.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
