class Session < Workflow
  has_many :jobs, class_name: "SessionJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :thermal, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Mesh"

  store_accessor :data, :name
  validates :name, presence: true

  # This workflow has a single job, so set workflow pbsid to this value
  def pbsid
    jobs.first.pbsid
  end

  # OSC::VNC Script view
  def script_view
    OSC::VNC::ScriptView.new(
      :vnc,
      'ruby',
      xstartup: staging_template_dir.join('xstartup'),
      outdir: staged_dir,
      geom: '1024x768'
    )
  end

  # Location of connection file
  def conn_file
    "#{staged_dir}/#{pbsid}.conn"
  end

  # OSC::VNC Connection view
  def conn_view
    session = OpenStruct.new(conn_file: conn_file, script: script_view)
    OSC::VNC::ConnView.new(session)
  end

  def running?
    jobs.first.status.running?
  end

  # Is the batch job starting? (i.e., running but no connection file yet)
  def starting?
    running? && !File.file?(conn_file)
  end

  # Template is located in jobs/session
  def staging_template_name
    "session"
  end

  # Don't copy the template directory over
  def stage
    staged_dir = OSC::Machete::JobDir.new(staging_target_dir).new_jobdir
    FileUtils.mkdir_p staged_dir
    staged_dir
  end

  # Copy the mesh upload over
  def after_stage(staged_dir)
    super
    FileUtils.cp parent.upload.file.path, staged_dir
  end

  # Use OSC::VNC to generate the batch script
  def build_jobs(staged_dir, job_list = [])
    script = staged_dir.join("session_main.sh")
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

  def ctsp_files_valid?
    files = %w(input.in node.in element.in param.in preWARP.txt time.out)
    if files.all? {|f| File.file? File.join(staged_dir, f)}
      return true
    else
      update_attribute(:fail_msg, "Missing CTSP input files")
      return false
    end
  end

  def warp3d_files_valid?
    wrp_file = Dir[File.join(staged_dir, "*.wrp")].first
    if wrp_file.nil?
      update_attribute(:fail_msg, "Missing WARP3D input file *.wrp")
      return false
    end
    wrp_name = File.basename(wrp_file, ".*")
    files= %W(
      #{wrp_name}.wrp #{wrp_name}.constraints #{wrp_name}.coordinates #{wrp_name}.incid
      VED.dat uexternal_data_file.inp output_commands.inp compute_commands_all_profiles.inp
    )
    if files.all? {|f| File.file? File.join(staged_dir, f)}
      return true
    else
      update_attribute(:fail_msg, "Missing WARP3D input files")
      false
    end
  end
end
