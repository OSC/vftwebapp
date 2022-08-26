class CreateMeshes < ActiveRecord::Migration[4.2]
  def change
    create_table :meshes do |t|
      t.text :data

      t.timestamps
    end
  end
end
