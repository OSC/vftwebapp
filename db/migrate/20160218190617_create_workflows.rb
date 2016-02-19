class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :type
      t.references :parent, index: true
      t.string :staged_dir
      t.text :data

      t.timestamps
    end
  end
end
