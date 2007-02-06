class EmailNotifier
  attr_accessor :emails
  
  def initialize(project = nil)
    @emails = []
  end

 def build_finished(build)
    return if @emails.empty?

    if build.failed?
      BuildMailer.deliver_build_failed(build, @emails)
    else
      last_build = build.last
      if last_build and last_build.failed?
        BuildMailer.deliver_build_fixed(build, @emails)
      end
    end
  end

end

Project.module_eval <<-EOL
  plugin :email_notifier

  def emails
    self.email_notifier.emails
  end
EOL
