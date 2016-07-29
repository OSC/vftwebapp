class MeshSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :link, :upload, :meta
  # has_many :sessions

  def link
    mesh_url(object, only_path: true)
  end

  def meta
    {
      sessions: {
        count: object.sessions.count,
        link: mesh_sessions_url(object, only_path: true)
      }
    }
  end

  def upload
    {
      link: object.upload.url,
      name: object.upload_file_name,
      size: object.upload_file_size,
    }
  end
end
