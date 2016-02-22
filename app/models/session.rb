class Session < Workflow
  has_many :jobs, class_name: "SessionJob", foreign_key: "workflow_id", dependent: :destroy
  has_many :thermals, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Mesh"

  def pbsid
    jobs.first.pbsid
  end

  def script_view
    OSC::VNC::ScriptView.new(
      :vnc,
      'ruby',
      xstartup: staging_template_dir.join('xstartup'),
      outdir: staged_dir,
      geom: '1024x768'
    )
  end

  def conn_file
    "#{staged_dir}/#{pbsid}.conn"
  end

  def conn_view
    session = OpenStruct.new(conn_file: conn_file, script: script_view)
    OSC::VNC::ConnView.new(session)
  end

  def starting?
    active? && !File.file?(conn_file)
  end

  def staging_template_name
    "session"
  end

  def after_stage(staged_dir)
    FileUtils.cp parent.upload.file.path, staged_dir
  end

  def build_jobs(staged_dir, job_list = [])
    self.staged_dir = staged_dir
    script = staged_dir.join("main.sh")
    File.open(script, 'w') do |f|
      f.write "#PBS -N VFTSolid\n"
      f.write "#PBS -l nodes=1:ppn=1:ruby\n"
      f.write "#PBS -l walltime=01:00:00\n"
      f.write "#PBS -j oe\n"
      f.write "#PBS -S /bin/bash\n\n"
      f.write script_view.render
    end
    job_list << OSC::Machete::Job.new(script: script, host: 'quick')
  end
end
