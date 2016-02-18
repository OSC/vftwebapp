class ThermalJob < Job
  belongs_to :workflow, class_name: "Thermal"
end
