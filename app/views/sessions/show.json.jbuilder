json.extract! @session, :name, :version, :created_at, :updated_at
json.upload do
  json.name @mesh.upload.file_file_name
  json.url @mesh.upload.file.url
end
