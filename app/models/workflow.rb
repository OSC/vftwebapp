class Workflow < ActiveRecord::Base
  has_machete_workflow_of :jobs

  store :data, accessors: [ :version, :error_reason ], coder: JSON

  # Default script name
  def script_name
    "main.sh"
  end

  # Default host
  def host
    "oakley"
  end

  def log_root
    File.join staged_dir, "results", "logs"
  end

  def error_root
    File.join staged_dir, "results", "errors"
  end

  def error_file
    "#{staging_template_name}.yml"
  end

  def error_path
    File.join error_root, error_file
  end

  # Create misc root directories under staged_dir
  def after_stage(staged_dir)
    FileUtils.mkdir_p log_root
    FileUtils.mkdir_p error_root
  end

  # Good default job builder for single job script
  def build_jobs(staged_dir, job_list = [])
    job_list << OSC::Machete::Job.new(script: staged_dir.join(script_name), host: host)
  end

  # Override Machete Workflow submit so that it doesn't delete the staged_dir
  # when job submission fails
  # Also set the workflow staged_dir at the beginning
  def submit(template_view=self)
    self.staged_dir = stage   # set global staged_dir needed throughout code
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
