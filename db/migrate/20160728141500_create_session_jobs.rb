class CreateSessionJobs < ActiveRecord::Migration[4.2]
  def change
    create_table :session_jobs do |t|
      t.references :session, index: true, foreign_key: true
      t.string :status
      t.text :job_cache

      t.timestamps
    end
  end
end
