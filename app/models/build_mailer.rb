class BuildMailer < ActionMailer::Base

  def build_report(build, recipients, from, subject, message, sent_at = Time.now)
    @subject    = "[CruiseControl] #{subject}"
    @body       = {
        :build => build,
        :message => message,
        :failures_and_errors => LogParser.new(build.output).failures_and_errors.map { |e| formatted_error(e) } }
    @recipients = recipients
    @from       = from
    @sent_on    = sent_at
    @headers    = {}
  end

  def test(recipients,  sent_at = Time.now)
    @subject    = 'Test CI E-mail'
    @body       = {:build => nil, :message => 'Hi, mom', :failures_and_errors => []}
    @recipients = recipients
    @sent_on    = sent_at
    @headers    = {}
  end

  def formatted_error(error)
    return "Name: #{error.test_name}\n" +
           "Type: #{error.type}\n" +
           "Message: #{error.message('\n', "\n")}\n\n" +
           error.stacktrace + "\n\n\n"
  end

end
