class Upload < ActiveRecord::Base
  attr_accessor :file_cache
  attr_accessor :file_cache_name
  has_attached_file :file
  do_not_validate_attachment_file_type :file
  validates_presence_of :file

  store :data, accessors: [], coder: JSON

  # Creates a cache file and sets the appropriate cache file attributes from
  # the file currently staged in `:file`
  def set_cache
    rm_cache
    self.file_cache = File.join Dir.tmpdir, "#{SecureRandom.urlsafe_base64}.cache"
    FileUtils.ln file.staged_path, file_cache
    self.file_cache_name = file_file_name
  end

  # Deletes the cached file and resets the appropriate cache file attributes
  def rm_cache
    FileUtils.rm file_cache if File.exist?(file_cache.to_s)
    self.file_cache = nil
    self.file_cache_name = nil
  end

  # Cache file if it is staged otherwise assign the file to the cached file
  before_validation do
    if file.staged?
      set_cache
    elsif File.exist?(file_cache.to_s)
      self.file = File.new file_cache
      self.file.instance_write(:file_name, file_cache_name)
    end
  end

  # Clean up cache file after we successfully save the file
  after_save do
    rm_cache
  end
end
