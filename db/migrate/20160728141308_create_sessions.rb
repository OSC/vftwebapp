class CreateSessions < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions do |t|
      t.references :mesh, index: true, foreign_key: true
      t.integer :state
      t.text :vftsolid_data
      t.text :thermal_data
      t.text :structural_data
      t.text :data
      t.string :staged_dir

      t.timestamps
    end
  end
end
