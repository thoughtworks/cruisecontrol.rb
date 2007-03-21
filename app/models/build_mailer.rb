class BuildMailer < ActionMailer::Base

  def build_report(build, recipients, from, subject, message, sent_at = Time.now)
    @subject    = "[CruiseControl] #{subject}"
    @body       = {:build => build, :message => message}
    @recipients = recipients
    @from       = from
    @sent_on    = sent_at
    @headers    = {}
  end

  def test(recipients,  sent_at = Time.now)
    @subject    = 'Test CI E-mail'
    @body       = {}
    @recipients = recipients
    @sent_on    = sent_at
    @headers    = {}
  end
end
