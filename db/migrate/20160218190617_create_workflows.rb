class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :type
      t.references :parent, index: true
      t.string :name
      t.string :staged_dir
      t.text :data
      t.integer :version

      t.timestamps
    end
  end
end
