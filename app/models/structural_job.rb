class StructuralJob < Job
  belongs_to :workflow, class_name: "Structural"

  def results_valid?
    super && workflow.paraview_files_valid?
  end
end
