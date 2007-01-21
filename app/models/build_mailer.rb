class BuildMailer < ActionMailer::Base

  def build_failed(build, recipients, sent_at = Time.now)
    @subject    = "#{build.project.name} Build #{build.label} - FAILED"
    @body       = {:build_log => build.output}
    @recipients = recipients
    @from       = 'cruisecontrol@thoughtworks.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def build_fixed(build, recipients, sent_at = Time.now)
    @subject    = "#{build.project.name} Build #{build.label} - FIXED"
    @body       = {:build_log => build.output}
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
