EmailSettings = Struct.new('EmailSettings', :address, :port, :domain, :authentication, :user_name, :password)

class AdminController < ApplicationController
  layout 'default'

  def email_settings
    s = ActionMailer::Base.server_settings
    @email_settings = EmailSettings.new(s[:address], s[:port], s[:domain],
                                        s[:authentication], s[:user_name], s[:password])
    
    if s.empty? or s[:address] == 'smtp.gmail.com'
      @email_type = :gmail
    elsif !s.has_key?(:user_name) && !s.has_key?(:password)
      @email_type = :no_authentication
    else
      @email_type = :manual
    end

    render :action => 'email_settings'
  end
  
  def update_email_settings
    ActionMailer::Base.server_settings = params[:email_settings]
    server.save
    flash[:notice] = "Settings updated."
    
    email_settings
  end
  
  def server_settings
  end
  
  def send_test_mail
    email_settings
    begin
      email = BuildMailer.deliver_test(params[:email][:recipients])
      flash[:notice] = "Email Sent to #{params[:email][:recipients]}"
    rescue
      flash[:notice] = "Error : #{$!}"
    end
  end
  
  private
  
  def server
    @server ||= Server.new
  end
end
