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

  def memento
    "  project.email_notifier.emails = [\n" +
    @emails.collect {|email| '    ' + email.to_s.strip.inspect }.join(",\n") + "\n" +
    "  ]"
  end
end

class Project
  plugin :email_notifier

  def emails
    self.email_notifier.emails
  end

  def add_email(email)
    emails << email
  end

  def delete_email(email)
    emails.delete(email)
  end
end
