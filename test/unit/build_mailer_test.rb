require File.dirname(__FILE__) + '/../test_helper'

class BuildMailerTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
    @expected.mime_version = '1.0'
  end

  # TODO: this test makes little sense as it doesn't invoke any production code directly. How to test mailer properly?
  def test_test
    Time.stubs(:now).returns(Time.at(100000))
    @expected.subject = 'Test CI E-mail'
    @expected.body = read_fixture('test')
    @expected.date = Time.now
    @expected.to = "Joe"

    assert_equal @expected.encoded, BuildMailer.create_test("Joe", @expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/build_mailer/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
