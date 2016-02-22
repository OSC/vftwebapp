class ThermalJob < Job
  belongs_to :workflow, class_name: "Thermal"

  def results_valid?
    workflow.create_structural
  end
end
