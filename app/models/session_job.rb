class SessionJob < Job
  belongs_to :workflow, class_name: "Session"

  def results_valid?
    workflow.create_thermal
  end

  def stop(update: true)
    return unless status.active?

    job.delete
    update(status: OSC::Machete::Status.passed) if update
    workflow.create_thermal if update
  end
end
