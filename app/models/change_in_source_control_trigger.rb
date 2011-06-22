# ChangeInSourceControlTrigger is one of two build triggers included in CC.rb by default (see also:
# SuccessfulBuildTrigger). It determines whether or not a build is necessary by utilizing the SCM
# a project to determine whether or not it is up to date.
class ChangeInSourceControlTrigger

  def initialize(triggered_project)
    @triggered_project = triggered_project
  end

  def build_necessary?(reasons)
    p = @triggered_project
    p.notify :polling_source_control
    
    if !p.source_control.up_to_date?(reasons)
      p.notify :new_revisions_detected, reasons.select { |r| r.is_a? SourceControl::AbstractRevision }
      return true
    else
      p.notify :no_new_revisions_detected
      return false
    end
  end

end
