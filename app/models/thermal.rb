class Thermal < Workflow
  has_many :jobs, class_name: "ThermalJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :structural, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Session"

  def staging_template_name
    "thermal"
  end
end
