class Session < Workflow
  has_many :jobs, class_name: "SessionJob", foreign_key: "workflow_id", dependent: :destroy
  has_many :thermals, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Mesh"

  def staging_template_name
    "session"
  end
end
