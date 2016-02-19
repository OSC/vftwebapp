class MeshUpload < Upload
  belongs_to :workflow, class_name: "Mesh"
end
