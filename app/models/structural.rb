class Structural < Workflow
  has_many :jobs, class_name: "StructuralJob", foreign_key: "workflow_id", dependent: :destroy
  belongs_to :parent, class_name: "Thermal"

  def staging_template_name
    "structural"
  end
end
