class Session < Workflow
  has_many :jobs, class_name: "SessionJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :thermal, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Mesh"

  store_accessor :data, :name
  validates :name, presence: true, allow_blank: true
  validates :name, length: { maximum: 30 }

  # Stage when session is first created
  before_create :stage

  attr_accessor :resx, :resy

  def resx
    @resx ||= 1024
  end

  def resy
    @resy ||= 768
  end

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
      geom: "#{resx}x#{resy}"
    )
  end

  # Location of connection file
  def conn_file
    staged_dir.join "#{pbsid}.conn"
  end

  # OSC::VNC Connection view
  def conn_view
    session = OpenStruct.new(conn_file: conn_file, script: script_view)
    OSC::VNC::ConnView.new(session)
  end

  def running?
    jobs.first.status.running?
  end

  def queued?
    jobs.first.status.queued?
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
    unless self.staged_dir
      self.staged_dir = OSC::Machete::JobDir.new(staging_target_dir).new_jobdir
      self.staged_dir.mkpath
    end
    self.staged_dir
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
      f.write "#PBS -l walltime=04:00:00\n"
      f.write "#PBS -j oe\n"
      f.write "#PBS -S /bin/bash\n\n"
      f.write script_view.render
    end
    job_list << OSC::Machete::Job.new(script: script, host: 'quick')
  end

  def ctsp_files_valid?
    files = %w(input.in node.in element.in param.in preWARP.txt time.out)
    if files.all? {|f| File.file? staged_dir.join(f)}
      return true
    else
      update_attribute(:fail_msg, "CTSP files were not properly exported")
      return false
    end
  end

  def warp3d_files_valid?
    # Get name of warp3d file
    wrp_file = Dir[staged_dir.join("*.wrp")].first
    if wrp_file.nil?
      update_attribute(:fail_msg, "WARP3D files were not properly exported")
      return false
    end
    wrp_name = File.basename(wrp_file, ".*")

    # Confirm warp3d input files exist
    files= %W(
      #{wrp_name}.wrp #{wrp_name}.constraints #{wrp_name}.coordinates #{wrp_name}.incid
      VED.dat uexternal_data_file.inp output_commands.inp compute_commands_all_profiles.inp
    )
    if files.all? {|f| File.file? staged_dir.join(f)}
      return true
    else
      update_attribute(:fail_msg, "WARP3D files were not properly exported")
      false
    end
  end
end
