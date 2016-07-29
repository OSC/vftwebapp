class SessionSerializer < ActiveModel::Serializer
  attributes :id, :state, :created_at, :link

  def link
    session_url(object, only_path: true)
  end
end
