class SessionJob < Job
  belongs_to :workflow, class_name: "Session"

  def results_valid?
    is_valid = workflow.ctsp_files_valid? && workflow.warp3d_files_valid?
    workflow.create_thermal if is_valid
    is_valid
  end

  def stop(update: true)
    return unless status.active?

    job.delete
    if update && status.running? && results_valid?
      update(status: OSC::Machete::Status.passed)
    elsif update
      update(status: OSC::Machete::Status.failed)
    end
  end
end
