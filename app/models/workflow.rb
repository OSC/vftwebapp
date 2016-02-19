class Workflow < ActiveRecord::Base
  has_machete_workflow_of :jobs

  store :data, accessors: [ :name, :version ], coder: JSON

  def build_jobs(staged_dir, job_list = [])
    job_list << OSC::Machete::Job.new(script: staged_dir.join("main.sh"))
  end
end
