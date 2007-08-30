require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SmtpTlsTest < Test::Unit::TestCase

  def test_starttls_should_return_false_when_server_responds_with_500_to_STARTTLS_directive
    smtp = Net::SMTP.new('localhost')
    smtp.expects(:getok).with('STARTTLS').raises(Net::SMTPSyntaxError)
    assert_equal false, smtp.send(:starttls)
  end

  def test_starttls_should_return_true_when_server_accepts_STARTTLS_directive
    smtp = Net::SMTP.new('localhost')
    smtp.expects(:getok).with('STARTTLS').returns("200-OK")
    assert_equal true, smtp.send(:starttls)
  end

end