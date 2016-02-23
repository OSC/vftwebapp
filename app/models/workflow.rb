class Workflow < ActiveRecord::Base
  has_machete_workflow_of :jobs

  store :data, accessors: [ :version ], coder: JSON

  def script_name
    "main.sh"
  end

  def host
    "oakley"
  end

  def build_jobs(staged_dir, job_list = [])
    job_list << OSC::Machete::Job.new(script: staged_dir.join(script_name), host: host)
  end
end
