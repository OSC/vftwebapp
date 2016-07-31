class Session < ActiveRecord::Base
  include AASM

  belongs_to :mesh
  has_one :session_job, dependent: :destroy

  store :data, accessors: [ :fails ], coder: JSON

  enum state: {
    vftsolid: 0,
    vftsolid_active: 1,
    vftsolid_failed: 2,
    thermal: 10,
    thermal_active: 11,
    thermal_failed: 12,
    structural: 20,
    structural_active: 21,
    structural_failed: 22,
    complete: 100
  }

  aasm column: :state, enum: true, whiny_transitions: false do
    state :vftsolid, initial: true
    state :vftsolid_active
    state :vftsolid_failed
    state :thermal
    state :thermal_active
    state :thermal_failed
    state :structural
    state :structural_active
    state :structural_failed
    state :complete

    event :submit do
      transitions from: :vftsolid,   to: :vftsolid_active,   guard: :submit_vftsolid
      transitions from: :thermal,    to: :thermal_active,    guard: :submit_thermal
      transitions from: :structural, to: :structural_active, guard: :submit_structural
    end

    event :finished do
      transitions from: :vftsolid_active,   to: :thermal,           guard: :vftsolid_valid?
      transitions from: :thermal_active,    to: :structural,        guard: :thermal_valid?
      transitions from: :structural_active, to: :complete,          guard: :structural_valid?
      transitions from: :vftsolid_active,   to: :vftsolid_failed
      transitions from: :thermal_active,    to: :thermal_failed
      transitions from: :structural_active, to: :structural_failed
    end

    event :stop, guards: [:stop_job] do
      transitions from: :vftsolid_active,   to: :thermal,           guard: :vftsolid_valid?
      transitions from: :vftsolid_active,   to: :vftsolid_failed
      transitions from: :thermal_active,    to: :thermal_failed
      transitions from: :structural_active, to: :structural_failed
    end

    event :back do
      transitions from: :thermal,    to: :vftsolid
      transitions from: :structural, to: :thermal
      transitions from: :complete,   to: :structural
    end
  end

  # After we create record & commit it, we should create the staging dir
  after_commit :create_staging, on: :create

  # Before we destroy record, we stop the job and delete staging dir
  # NB: `prepend: true` tells this to run before the job is destroyed so we can
  # stop it first and recover if there is a problem
  before_destroy prepend: true do |s|
    if s.may_stop?
      s.stop! ? s.delete_staging : false
    else
      s.delete_staging
    end
  end

  # After session is found, flush the NFS cache so we get a fresh look at the
  # files in the staged_dir
  after_find do |s|
    Dir.open(staged_dir.to_s).close if s.active? && staged_dir.directory?
  end

  # All active sessions
  def self.active
    vftsolid_active.thermal_active.structural_active
  end

  # All failed sessions
  def self.failed
    vftsolid_failed.thermal_failed.structural_failed
  end

  # Resolution used for VFTSolid desktop
  def resx
    @resx ||= 1024
  end

  def resy
    @resy ||= 768
  end

  attr_writer :resx, :resy

  # Provide getter/setter for staged_dir
  def staged_dir
    Pathname.new(super) if super
  end

  def staged_dir=(dir)
    super(dir.to_s)
  end

  # Initialize fails to empty array
  def fails
    super || []
  end

  # Whether this session has been submitted
  def not_submitted?
    vftsolid? || thermal? || structural?
  end

  # Whether this session is active
  def active?
    vftsolid_active? || thermal_active? || structural_active?
  end

  # Wether this session has failed
  def failed?
    vftsolid_failed? || thermal_failed? || structural_failed?
  end

  #
  # Staging / Controlling jobs helpers
  #

  # Stage the working directory
  # "OOD_DATAROOT/sessions/<id>"
  def create_staging
    # skip callbacks or you get infinite loop
    update_column :staged_dir, ood_dataroot.join('sessions', id.to_s).to_s
    staged_dir.mkpath
    FileUtils.cp mesh.upload.path, staged_dir # copy the mesh
  end

  # Delete staged dir
  def delete_staging
    FileUtils.rm_rf(staged_dir) if staged_dir && staged_dir.exist?
  end

  # Connection view for VFTSolid job, so you can connect to it
  def vftsolid_conn_view
    conn_file = staged_dir.join("#{session_job.pbsid}.conn")
    session = OpenStruct.new(conn_file: conn_file, script: vftsolid_script_view)
    OSC::VNC::ConnView.new session
  end

  # private
    # Data root where all data is stored for each user
    def ood_dataroot
      Pathname.new ENV['OOD_DATAROOT']
    end

    #
    # VFTSolid helpers
    #

    # Assets where VFTSolid xstartup + fvwm is stored & re-used by jobs
    def vftsolid_assets
      ood_dataroot.join('vftsolid_assets')
    end

    # Script view defining a VNC session that launches VFTSolid assets
    def vftsolid_script_view
      OSC::VNC::ScriptView.new(
        :vnc,
        'ruby',
        xstartup: vftsolid_assets.join('xstartup'),
        outdir: staged_dir,
        geom: "#{resx}x#{resy}"
      )
    end

    # Submit VFTSolid job
    def submit_vftsolid
      # stage vftsolid xstartup + fvwm
      vftsolid_assets.mkpath
      `rsync -avu "#{Rails.root.join('jobs', 'vftsolid')}/" "#{vftsolid_assets}"`

      # build job
      script = staged_dir.join('vftsolid_main.sh')
      File.open(script, 'w') do |f|
        f.write <<-EOF.gsub(/^ {8}/, '')
          #PBS -N VFTSolid
          #PBS -l nodes=1:ppn=1:ruby
          #PBS -l walltime=04:00:00
          #PBS -j oe
          #PBS -S /bin/bash
        EOF
        f.write vftsolid_script_view.render
      end
      job = OSC::Machete::Job.new(script: script, host: 'quick')

      # submit job
      submit_machete_job(job) ? create_session_job(job: job) : false
    end

    # Check if VFTSolid results are valid
    def vftsolid_valid?
      update_attribute(:fails, [])
      [
        vftsolid_exported_ctsp_files?,
        vftsolid_exported_warp3d_files?,
        vftsolid_exported_warp3d_constraints?
      ].all? {|b| b}
    end

    # Check CTSP input files were exported
    def vftsolid_exported_ctsp_files?
      files = %w(input.in node.in element.in param.in preWARP.txt time.out)
      unless files.all? {|f| File.file? staged_dir.join(f)}
        update_attribute(:fails, fails + ["CTSP files were not properly exported"])
        return false
      end
      true
    end

    # Check WARP3D input files were exported
    def vftsolid_exported_warp3d_files?
      # Check for *.wrp
      if wrp_files.empty?
        update_attribute(:fails, fails + ["WARP3D files were not properly exported"])
        return false
      end

      # Check that each *.wrp has necessary files
      wrp_files.each do |name, file|
        files = %W(
          #{name}.coordinates #{name}.incid VED.dat uexternal_data_file.inp
          output_commands.inp compute_commands_all_profiles.inp
        )
        unless files.all? {|f| File.file? staged_dir.join(f)}
          update_attribute(:fails, fails + ["WARP3D files were not properly exported for #{file.basename}"])
          return false
        end
      end
      true
    end

    # Check WARP3D constraints was exported
    def vftsolid_exported_warp3d_constraints?
      wrp_files.each do |name, file|
        unless File.file?(staged_dir.join("#{name}.constraints"))
          update_attribute(:fails, fails + ["WARP3D constraints file was not exported for #{file.basename}"])
          return false
        end
      end
      true
    end

    #
    # Thermal helpers
    #

    # Submit thermal job
    def submit_thermal
      true
    end

    # Check if thermal results are valid
    def thermal_valid?
      true
    end

    #
    # Structural helpers
    #

    # Submit structural job
    def submit_structural
      true
    end

    # Check if structural results are valid
    def structural_valid?
      true
    end

    # Submit a machete job object to PBS
    def submit_machete_job(job)
      job.submit
      true
    rescue PBS::Error => e
      msg = "A PBS::Error occurred when submitting jobs for session #{id}: #{e.message}"
      errors[:base] << msg
      Rails.logger.error(msg)
      false
    end

    # Stop this workflow if it is active
    def stop_job
      session_job.stop
      session_job.destroy
      true
    rescue PBS::Error => e
      msg = "A PBS::Error occurred when trying to stop the job for session #{id}: #{e.message}"
      errors[:base] << msg
      Rails.logger.error(msg)
      false
    end

    # List of warp input files
    def wrp_files
      Dir[staged_dir.join('*.wrp')].each_with_object({}) do |f, h|
        name = File.basename(f, '.*')
        h[name.to_sym] = Pathname.new f
      end
    end
end
