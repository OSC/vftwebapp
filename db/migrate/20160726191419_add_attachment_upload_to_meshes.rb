class AddAttachmentUploadToMeshes < ActiveRecord::Migration
  def self.up
    change_table :meshes do |t|
      t.attachment :upload
    end
  end

  def self.down
    remove_attachment :meshes, :upload
  end
end
