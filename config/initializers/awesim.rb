# AweSim configuration

class MyFilesRackApp
  def self.call(env)
    root = OodAppkit.dataroot
    Rack::Directory.new(
      root,
      Rack::File.new(root, {}, 'application/octet-stream')
    ).call(env)
  end
end

OodAppkit.configure do |config|
  config.docs.uri = "/wiki"
  config.docs.path = "wiki"
  config.files_rack_app = MyFilesRackApp
end
