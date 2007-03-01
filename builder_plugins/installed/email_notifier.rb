# CruiseControl.rb can send email notices whenever build is broken or fixed. To make it happen, you need to tell it how
# to send email, and who to send it to. Do the following:
# 
# 1. Configure SMTP server connection. Copy [cruise]/config/site_config.rb_example to ~cruise/config/site_config.rb,
#    read it and edit according to your situation.
# 
# 2. Tell the builder, whom do you want to receive build notices, by placing the following line in cruise_config.rb:
# 
# <pre><code>Project.configure do |project|
#   ...
#   project.email_notifier.emails = ['john@doe.com', 'jane@doe.com']
#   ...
# end</code></pre>
#
class EmailNotifier
  attr_accessor :emails
  
  def initialize(project = nil)
    @emails = []
  end

  def build_finished(build)
    return if @emails.empty? or !build.failed?

    email :deliver_build_failed, build
  end

  def build_fixed(build, previous_build)
    return if @emails.empty?
    
    email :deliver_build_fixed, build
  end
  
  private
  
  def email(message, build)
    BuildMailer.send(message, build, @emails)
    CruiseControl::Log.event("Sent e-mail to #{@emails.size == 1 ? "1 person" : "#{@emails.size} people"}", :info)
  rescue
    settings = ActionMailer::Base.smtp_settings.map {|k,v| "  #{k.inspect} = #{v.inspect}"}.join("\n")
    CruiseControl::Log.event("Error sending e-mail - current server settings are :\n#{settings}", :error)
    raise
  end

end

Project.plugin :email_notifier