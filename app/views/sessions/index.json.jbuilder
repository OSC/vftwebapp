json.array!(@sessions) do |session|
  json.extract! session, :name, :version
  json.url session_url(session, format: :json)
end
