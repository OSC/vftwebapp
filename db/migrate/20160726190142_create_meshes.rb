class CreateMeshes < ActiveRecord::Migration
  def change
    create_table :meshes do |t|
      t.text :data

      t.timestamps
    end
  end
end
