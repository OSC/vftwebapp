class Thermal < Workflow
  has_many :jobs, class_name: "ThermalJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :structural, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Session"

  def nodes
    1
  end

  def hours
    1
  end

  def staging_template_name
    "thermal"
  end

  def script_name
    "thermal_main.sh"
  end

  # Re-use staged dir from Session
  def stage
    staged_dir = Pathname.new(parent.staged_dir)
    FileUtils.cp_r staging_template_dir.to_s + "/.", staged_dir
    staged_dir
  end
end
