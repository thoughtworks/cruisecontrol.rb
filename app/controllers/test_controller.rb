class TestController < ApplicationController
  layout "default"
  
  def test_mail
  end

  def send_test_mail
    time = Time.now.strftime("%I:%M:%S")
    email = BuildMailer.deliver_test(params[:email][:recipients])
    render :text => email_result("green", "Email Sent... (#{time})")
  rescue
    render :text => email_result("red", "Error : #{$!} (%{time})")
  end

  def email_result(color, message)
    "<font color='#{color}'>#{message}</font>"
  end
end
