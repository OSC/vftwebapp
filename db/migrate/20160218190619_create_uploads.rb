class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.string :type
      t.references :workflow, index: true
      t.attachment :file
      t.text :data

      t.timestamps
    end
  end
end
