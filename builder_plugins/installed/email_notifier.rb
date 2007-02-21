# this plugin sends e-mail on build events
#
# to read more, go to the "manual":/documentation/manual.html
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