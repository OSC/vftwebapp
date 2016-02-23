class Structural < Workflow
  has_many :jobs, class_name: "StructuralJob", foreign_key: "workflow_id", dependent: :destroy
  belongs_to :parent, class_name: "Thermal"

  def hours
    1
  end

  def staging_template_name
    "structural"
  end

  def script_name
    "structural_main.sh"
  end

  def host
    "ruby"
  end

  # Re-use staged dir from Thermal
  def stage
    staged_dir = Pathname.new(parent.staged_dir)
    FileUtils.cp_r staging_template_dir.to_s + "/.", staged_dir
    staged_dir
  end
end
