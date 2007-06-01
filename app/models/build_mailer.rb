class BuildMailer < ActionMailer::Base

  def build_report(build, recipients, from, subject, message, sent_at = Time.now)
    @subject    = "[CruiseControl] #{subject}"
    @body       = {:build => build, :message => message, :log_parser => LogParser.new(build.output)}
    @failures_and_errors = LogParser.new(build.output).failures_and_errors.map { |e| formatted_error(e) }  
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

  def formatted_error
    return "Name: #{test_error.test_name}\n" +
           "Type: #{test_error.type}\n" +
           "Message: #{test_error.message('\n', "\n")}\n\n" +
           test_error.stacktrace + "\n\n\n"
  end

end
