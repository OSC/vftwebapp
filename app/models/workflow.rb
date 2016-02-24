class Workflow < ActiveRecord::Base
  has_machete_workflow_of :jobs

  store :data, accessors: [ :version, :fail_msg ], coder: JSON

  # Default script name
  def script_name
    "main.sh"
  end

  # Default host
  def host
    "oakley"
  end

  # Record staged_dir as a string
  def staged_dir=(dir)
    super(dir.to_s)
  end

  # Treat staged_dir as a Pathname object
  def staged_dir
    Pathname.new(super)
  end

  def log_root
    staged_dir.join "results", "logs"
  end

  def log_file_name
    "#{staging_template_name}.log"
  end

  def log_file
    log_root.join log_file_name
  end

  def error_root
    staged_dir.join "results", "errors"
  end

  def error_file_name
    "#{staging_template_name}.yml"
  end

  def error_file
    error_root.join error_file_name
  end

  # Create misc root directories under staged_dir
  def after_stage(staged_dir)
    log_root.mkpath
    error_root.mkpath
  end

  # Good default job builder for single job script
  def build_jobs(staged_dir, job_list = [])
    job_list << OSC::Machete::Job.new(script: staged_dir.join(script_name), host: host)
  end

  # - Set the workflow staged_dir at the beginning so other methods can use it
  # - Override Machete Workflow submit so that it doesn't delete the staged_dir
  #   when job submission fails
  def submit(template_view=self)
    self.staged_dir = stage   # set staged_dir
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
