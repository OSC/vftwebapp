class ThermalJob < Job
  belongs_to :workflow, class_name: "Thermal"

  def results_valid?
    is_valid = super
    workflow.create_structural if is_valid
    is_valid
  end
end
