class EmailNotifier
  attr_accessor :emails
  
  def initialize(project = nil)
    @emails = []
  end

  def build_finished(build)
    return if @emails.empty?
    BuildMailer.deliver_build_failed(build, @emails) if build.failed?
  end

  def build_fixed(build)
    return if @emails.empty?
    BuildMailer.deliver_build_fixed(build, @emails)
  end

end

Project.module_eval <<-EOL
  plugin :email_notifier

  def emails
    self.email_notifier.emails
  end
EOL
