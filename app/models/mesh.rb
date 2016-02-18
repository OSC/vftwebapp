class Mesh < Workflow
  has_many :jobs, class_name: "MeshJob", foreign_key: "workflow_id", dependent: :destroy
  has_many :sessions, foreign_key: "parent_id", dependent: :destroy

  def staging_template_name
    "mesh"
  end
end
