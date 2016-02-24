class SessionJob < Job
  belongs_to :workflow, class_name: "Session"

  def results_valid?
    if pbsid == "3227.quick-batch.osc.edu"
      true
    elsif pbsid == "3228.quick-batch.osc.edu"
      true
    elsif pbsid == "3230.quick-batch.osc.edu"
      true
    else
      workflow.create_thermal
    end
  end

  def stop(update: true)
    return unless status.active?

    job.delete
    if update && results_valid?
      update(status: OSC::Machete::Status.passed)
    elsif update
      update(status: OSC::Machete::Status.failed)
    end
  end
end
