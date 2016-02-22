class SessionJob < Job
  belongs_to :workflow, class_name: "Session"

  def results_valid?
    workflow.create_thermal
  end
end
