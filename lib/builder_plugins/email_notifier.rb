# CruiseControl.rb can send email notices whenever build is broken or fixed. To make it happen, you need to tell it how
# to send email, and who to send it to. Do the following:
# 
# 1. Configure SMTP server connection. Open *$cruise_data*/site_config.rb,
#    read the comments in it and edit according to your situation.

# 2. Tell the builder, whom do you want to receive build notices.
# <pre><code>Project.configure do |project|
#   ...
#   project.email_notifier.emails = ['john@doe.com', 'jane@doe.com']
#   ...
# end</code></pre>
# Please note, this setting can be put into project specific cruise_config.rb, usually at ~/.cruise/projects/YourProject/cruise_config.rb
# Or be put into repository specific cruise_config.rb, ie, YourRepository/cruise_config.rb

# You can also specify who to send the email from, either for the entire site by setting Configuration.email_from
# in *$cruise_data*//site_config.rb, or on a per project basis, by placing the following line in cruise_config.rb:
# <pre><code>Project.configure do |project|
#   ...
#   project.email_notifier.from = "cruisecontrol@doe.com"
#   ...
# end</code></pre>
#
# The emails from CruiseControl.rb can have a lot of details about the build, or just a link to the build page in the dashboard.
# Usually, you will want the latter. Set the dashboard URL in the *$cruise_data*/site_config.rb as follows:
#
# <pre><code>Configuration.dashboard_url = 'http://your.host.name.com:3333'</pre></code>
class EmailNotifier < BuilderPlugin
  attr_accessor :emails
  attr_writer :from
  
  def initialize(project = nil)
    @emails = []
  end

  def from
    @from || Configuration.email_from
  end

  def build_finished(build)
    return if @emails.empty? or not build.failed?
    email :build_report, build, "#{build.project.name} build #{build.abbreviated_label} failed",
          "The build failed."
  end

  def release_note_generated(build , message , email = nil)
    @emails = email.split(',') unless email.to_s.empty?
    return if @emails.empty?
    email(:send_release_note, build, build.project.name, message)
  end

  def build_fixed(build, previous_build)
    return if @emails.empty?
    email :build_report, build, "#{build.project.name} build #{build.abbreviated_label} fixed",
          "The build has been fixed."
  end
  
  private
  
  def email(template, build, *args)
    BuildMailer.send(template, build, @emails, from, *args).deliver
    CruiseControl::Log.event("Sent e-mail to #{@emails.size == 1 ? "1 person" : "#{@emails.size} people"}", :debug)
  rescue
    settings = ActionMailer::Base.smtp_settings.map { |k,v| "  #{k.inspect} = #{v.inspect}" }.join("\n")
    CruiseControl::Log.event("Error sending e-mail - current server settings are :\n#{settings}", :error)
    raise
  end

end

Project.plugin :email_notifier
