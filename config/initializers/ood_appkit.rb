# OodAppkit configuration

class MyFilesRackApp < OodAppkit::FilesRackApp
  def call(env)
    Rack::Directory.new(
      root,
      Rack::File.new(root, {'Content-Disposition' => 'attachment'}, 'application/octet-stream')
    ).call(env)
  end
end

OodAppkit.configure do |config|
  config.routes.files_rack_app = false
end

OODClusters = OodCore::Clusters.new(
  OodAppkit.clusters.select(&:job_allow?)
)
