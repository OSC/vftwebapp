class Session < ActiveRecord::Base
  include AASM

  belongs_to :mesh
  has_one :session_job, dependent: :destroy

  store :data, accessors: [ :fails ], coder: JSON
  store :thermal_data, accessors: [ :thermal_walltime ], coder: JSON
  store :structural_data, accessors: [ :structural_walltime ], coder: JSON

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

    event :validate do
      transitions from: :vftsolid_failed,   to: :thermal,           guard: :vftsolid_valid?
      transitions from: :thermal_failed,    to: :structural,        guard: :thermal_valid?
      transitions from: :structural_failed, to: :complete,          guard: :structural_valid?
      transitions from: :vftsolid_failed,   to: :vftsolid_failed
      transitions from: :thermal_failed,    to: :thermal_failed
      transitions from: :structural_failed, to: :structural_failed
    end

    event :back do
      transitions from: :thermal,    to: :vftsolid
      transitions from: :structural, to: :thermal
      transitions from: :complete,   to: :structural
      transitions from: :vftsolid_failed,   to: :vftsolid
      transitions from: :thermal_failed,    to: :thermal
      transitions from: :structural_failed, to: :structural
    end

    event :skip do
      transitions from: :vftsolid,   to: :thermal,    guard: :vftsolid_valid?
      transitions from: :thermal,    to: :structural, guard: :thermal_valid?
      transitions from: :structural, to: :complete,   guard: :structural_valid?
      transitions from: :vftsolid,   to: :vftsolid_failed
      transitions from: :thermal,    to: :thermal_failed
      transitions from: :structural, to: :structural_failed
    end
  end

  # After we create record & commit it, we should create the staging dir
  after_commit :create_staging, on: :create

  # Before we destroy record, we stop the job and delete staging dir
  # NB: `prepend: true` tells this to run before the job is destroyed so we can
  # stop it first and recover if there is a problem
  before_destroy prepend: true do |s|
    if s.active?
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

  # Uexternal model object
  def uexternal
    @uexternal ||= Uexternal.new(file: uexternal_file).parse
  end

  def uexternal_attributes=(attributes)
    attributes.each do |k, v|
      uexternal.send("#{k}=", v)
    end
    uexternal.write
  end

  # Resolution used for VFTSolid desktop
  def resx
    @resx || 1024
  end

  def resy
    @resy || 768
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
    log_root.mkpath
    error_root.mkpath
    FileUtils.cp mesh.upload.path, staged_dir # copy the mesh
  end

  # Delete staged dir
  def delete_staging
    FileUtils.rm_rf(staged_dir) if staged_dir && staged_dir.exist?
  end

  # Connection view for VFTSolid job, so you can connect to it
  def vftsolid_conn_view
    return nil unless vftsolid_active?
    conn_file = staged_dir.join("#{session_job.pbsid}.conn")
    return nil unless conn_file.file?
    session = OpenStruct.new(conn_file: conn_file, script: vftsolid_script_view)
    OSC::VNC::ConnView.new session
  end

  # Staged log root
  def log_root
    staged_dir.join 'results', 'logs'
  end

  # Staged error root
  def error_root
    staged_dir.join 'results', 'errors'
  end

  #
  # Thermal mustache values
  #

  # Walltime used for thermal calculation
  def thermal_walltime
    super || 1
  end

  # Number of nodes used in thermal calculation
  def thermal_nodes
    processes = Dir[staged_dir.join("CTSPsubd*")].length
    processes.zero? ? 1 : (processes - 1) / ppn + 1
  end

  # Procs per node used in thermal calculation
  def thermal_ppn
    20
  end

  # Log file for thermal calculation
  def thermal_log_file
    log_root.join 'thermal.log'
  end

  # Error file for thermal calculation
  def thermal_error_file
    error_root.join 'thermal.err'
  end

  #
  # Structural mustache values
  #

  # Walltime used for structural calculation
  def structural_walltime
    super || 1
  end

  # Log file for structural calculation
  def structural_log_file
    log_root.join 'structural.log'
  end

  # Error file for structural calculation
  def structural_error_file
    error_root.join 'structural.err'
  end

  # Input *.wrp file for structural calculation
  def warp3d_input_file_name
    name, file = wrp_files.first
    file.basename.to_s
  end

  # Flat file used for structural calculation
  def warp3d_flat_file_name
    name, file = wrp_files.first
    "#{name}_flat.text"
  end

  # Batch messages output by structural calculation
  def warp3d_batch_messages_file_name
    name, file = wrp_files.first
    "#{name}.batch_messages"
  end

  # Path to batch messages output by structural calculation
  def warp3d_batch_messages_file
    staged_dir.join warp3d_batch_messages_file_name
  end

  # Parse the WARP3D log file
  def parse_warp3d_log_file
    return unless staged_dir.exist?

    # get current profile step
    cur_profile = 0
    if warp3d_batch_messages_file.file?
      File.open(warp3d_batch_messages_file) do |f|
        lines = f.grep(/new profile/)
        cur_profile = lines.last.split[7].to_i unless lines.empty?
      end
    end

    # get total number of profile steps
    temp_file = staged_dir.join('warp_temp_2_files.txt')
    num_profile = 1
    if temp_file.file?
      num_profile = IO.readlines(temp_file).last.split[0].to_i
    end

    return cur_profile, num_profile
  end

  #
  # Uexternal helpers
  #

  # Name of the uexternal file
  def uexternal_file_name
    "uexternal_data_file.inp"
  end

  # Path to the uexternal file
  def uexternal_file
    staged_dir.join uexternal_file_name
  end

  # Read an array from the contents of the file
  def read_uexternal_file
    return nil unless uexternal_file.file?
    @contents ||= File.read(uexternal_file.to_s).scan(/^[^!].+/).map(&:strip)
  end

  #
  # Paraview
  #

  # Assets for Paraview jobs
  def paraview_assets
    ood_dataroot.join('paraview_assets')
  end

  # Output dir for Paraview jobs
  def paraview_outdir
    ood_dataroot.join('paraview_outdir')
  end

  # The script view used to launch Paraview VNC session
  def paraview_script_view
    OSC::VNC::ScriptView.new(
      :vnc,
      'oakley',
      subtype: :shared,
      xstartup: paraview_assets.join('xstartup'),
      outdir: paraview_outdir,
      geom: "#{resx}x#{resy}",
      tcp_server?: false
    )
  end

  # The connection view used to connect to Paraview VNC session
  def paraview_conn_view(job_id)
    conn_file = paraview_outdir.join("#{job_id}.conn")
    return nil unless conn_file.file?
    session = OpenStruct.new(conn_file: conn_file, script: paraview_script_view)
    OSC::VNC::ConnView.new session
  end

  # Generate Paraview AweSim connect link
  def submit_paraview
    # stage paraview xstartup + fvwm
    paraview_assets.mkpath
    `rsync -avu "#{Rails.root.join('jobs', 'paraview')}/" "#{paraview_assets}"`
    paraview_outdir.mkpath

    # build job
    script = Tempfile.new('paraview', paraview_outdir.to_s)
    script.write yield
    script.write paraview_script_view.render
    script.close
    job = OSC::Machete::Job.new(script: script.path, host: 'quick')

    # submit job
    submit_machete_job(job) ? (job_id = job.pbsid) : (return false)
    script.unlink

    # get connection info
    Timeout::timeout(120) do
      while true
        Dir.open(paraview_outdir.to_s).close # flush nfs cache
        if conn_view = paraview_conn_view(job_id)
          return conn_view.render(:awesim)
        end
        sleep 1
      end
    end
  rescue Timeout::Error
    false
  end

  # Whether we can display thermal paraview
  def thermal_paraview?
    ctsp_paraview_generated?(false)
  end

  # Generate Thermal Paraview awesim connect link
  def thermal_paraview
    submit_paraview do
      <<-EOF.gsub(/^ {8}/, '')
        #PBS -N Thermal-Paraview
        #PBS -l nodes=1:ppn=1:oakley
        #PBS -l walltime=04:00:00
        #PBS -j oe
        #PBS -S /bin/bash

        export DATAFILE="#{staged_dir.join('ctsp.case')}"
      EOF
    end
  end

  # Whether we can display structural paraview
  def structural_paraview?
    warp3d_paraview_generated?(false)
  end

  # Generate Structural Paraview awesim connect link
  def structural_paraview
    submit_paraview do
      <<-EOF.gsub(/^ {8}/, '')
        #PBS -N Structural-Paraview
        #PBS -l nodes=1:ppn=1:oakley
        #PBS -l walltime=04:00:00
        #PBS -j oe
        #PBS -S /bin/bash

        export DATAFILE="#{staged_dir.join('wrp.exo')}"
        export IS_STRUCTURAL="true"
      EOF
    end
  end

  private
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

      # For now only allow one *.wrp
      if wrp_files.length > 1
        update_attribute(:fails, fails + ["Only allows a single *.wrp file in directory (please rename or delete the other)"])
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
          update_attribute(:fails, fails + ["WARP3D constraints file was not exported for #{file.basename} (please add it and click \"Try again\")"])
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
      # render mustache files
      FileUtils.cp_r "#{Rails.root.join('jobs', 'thermal')}/.", "#{staged_dir}"
      OSC::Machete::Location.new(staged_dir).render(self)

      # stage roots
      log_root.mkpath
      error_root.mkpath
      thermal_error_file.delete if File.file?(thermal_error_file)

      # build job
      job = OSC::Machete::Job.new(script: staged_dir.join('thermal_main.sh'), host: 'ruby')

      # submit job
      submit_machete_job(job) ? create_session_job(job: job) : false
    end

    # Check if thermal results are valid
    def thermal_valid?
      update_attribute(:fails, [])
      [
        ctsp_generated_error_file?,
        ctsp_created_warp3d_files?,
        ctsp_paraview_generated?
      ].all? {|b| b}
    end

    # Check if CTSP generated an error file
    def ctsp_generated_error_file?
      if File.file? thermal_error_file
        update_attribute(:fails, fails + [File.read(thermal_error_file).strip])
        return false
      end
      true
    end

    # Check WARP3D inputs were generated
    def ctsp_created_warp3d_files?
      files = %w(warp_temp_2_files.bin warp_temp_2_files.txt)
      unless files.all? {|f| File.file? staged_dir.join(f)}
        update_attribute(:fails, fails + ["WARP3D input files were not generated"])
        return false
      end
      true
    end

    # Check that paraview inputs were generated
    def ctsp_paraview_generated?(update_fails = true)
      files = %w(ctsp.case ctsp.geom ctsp.mtemp ctsp.mtemp_wp)
      unless files.all? {|f| File.file? staged_dir.join(f)}
        update_fails && update_attribute(:fails, fails + ["Paraview input files were not generated"])
        return false
      end
      true
    end

    #
    # Structural helpers
    #

    # Submit structural job
    def submit_structural
      # render mustache files
      FileUtils.cp_r "#{Rails.root.join('jobs', 'structural')}/.", "#{staged_dir}"
      OSC::Machete::Location.new(staged_dir).render(self)

      # stage roots
      log_root.mkpath
      error_root.mkpath
      structural_error_file.delete if File.file?(structural_error_file)
      warp3d_batch_messages_file.delete if File.file?(warp3d_batch_messages_file)

      # add proper headers to material files
      uexternal.materials.each_with_index do |file, idx|
        file_path = staged_dir.join file
        lines = File.readlines(file_path)
        lines[0] = "#{idx + 1}\n"
        File.open(file_path, 'w') do |f|
          f.puts(lines)
        end
      end

      # build job
      job = OSC::Machete::Job.new(script: staged_dir.join('structural_main.sh'), host: 'ruby')

      # submit job
      submit_machete_job(job) ? create_session_job(job: job) : false
    end

    # Check if structural results are valid
    def structural_valid?
      update_attribute(:fails, [])
      [
        warp3d_generated_error_file?,
        warp3d_soln_valid?,
        warp3d_paraview_generated?
      ].all? {|b| b}
    end

    # Check if WARP3D generated an error file
    def warp3d_generated_error_file?
      if File.file? structural_error_file
        update_attribute(:fails, fails + [File.read(structural_error_file).strip])
        return false
      end
      true
    end

    # Check if WARP3D diverged
    def warp3d_soln_valid?
      cur_profile, num_profile = parse_warp3d_log_file

      unless cur_profile == num_profile
        update_attribute(:fails, fails + ["WARP3D solution may have diverged"])
        return false
      end
      true
    end

    # Chack if paraview input files were generated
    def warp3d_paraview_generated?(update_fails = true)
      files = %w(wrp.exo)
      unless files.all? {|f| File.file? staged_dir.join(f)}
        update_fails && update_attribute(:fails, fails + ["Paraview input file 'wrp.exo' was not generated"])
        return false
      end
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
      if session_job
        session_job.stop
        session_job.destroy
      end
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
