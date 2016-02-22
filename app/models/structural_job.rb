class StructuralJob < Job
  belongs_to :workflow, class_name: "Structural"
end
