class Mesh < Workflow
  has_many :jobs, class_name: "MeshJob", foreign_key: "workflow_id", dependent: :destroy
  has_many :sessions, foreign_key: "parent_id", dependent: :destroy

  store_accessor :data, :name
  validates :name, presence: true

  has_one :upload, class_name: "MeshUpload", foreign_key: "workflow_id", dependent: :destroy
  accepts_nested_attributes_for :upload, allow_destroy: true
  validates_associated :upload

  def staging_template_name
    "mesh"
  end

  # Define tasks to do after staging template directory typically copy over
  # uploaded files here
  def after_stage(staged_dir)
    FileUtils.cp upload.file.path, staged_dir
  end
end
