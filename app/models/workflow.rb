class Workflow < ActiveRecord::Base
  has_machete_workflow_of :jobs

  store :data, accessors: [ :version ], coder: JSON

  def script_name
    "main.sh"
  end

  def host
    "oakley"
  end

  # Good default job builder for single job script
  def build_jobs(staged_dir, job_list = [])
    job_list << OSC::Machete::Job.new(script: staged_dir.join(script_name), host: host)
  end

  # Override Machete Workflow submit so that it doesn't delete the staged_dir
  # when job submission fails
  def submit(template_view=self)
    staged_dir = stage
    render_mustache_files(staged_dir, template_view)
    after_stage(staged_dir)
    jobs = build_jobs(staged_dir)
    if submit_jobs(jobs)
      save_jobs(jobs, staged_dir)
    else
      # FileUtils.rm_rf staged_dir.to_s
      false
    end
  end
end
