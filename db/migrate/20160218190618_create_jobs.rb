class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.string :type
      t.references :workflow, index: true
      t.string :status
      t.text :job_cache

      t.timestamps
    end
  end
end
