class ChangeInSourceControlTrigger
  def initialize(triggered_project)
    @triggered_project = triggered_project
  end

  def build_necessary?(reasons)
    p = @triggered_project
    p.notify :polling_source_control
    
    if !p.source_control.up_to_date?(reasons)
      p.notify :new_revisions_detected, reasons.flatten.find_all{|reason| reason.is_a? Revision}
      return true
    else
      p.notify :no_new_revisions_detected
      return false
    end
  end
end
