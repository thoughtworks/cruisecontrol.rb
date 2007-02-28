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
    return if @emails.empty?
    BuildMailer.deliver_build_failed(build, @emails) if build.failed?
  end

  def build_fixed(build, previous_build)
    return if @emails.empty?
    BuildMailer.deliver_build_fixed(build, @emails)
  end

end

Project.plugin :email_notifier