class MeshJob < Job
  belongs_to :workflow, class_name: "Mesh"
end
