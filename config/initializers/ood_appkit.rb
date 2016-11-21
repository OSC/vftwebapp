# OodAppkit configuration

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
  config.routes.files_rack_app = MyFilesRackApp
end
