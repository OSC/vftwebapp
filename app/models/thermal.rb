class Thermal < Workflow
  has_many :jobs, class_name: "ThermalJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :structural, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Session"

  # Set staged dir when first created
  before_create do
    self.staged_dir = parent.staged_dir
  end

  attr_accessor :hours

  attr_accessor :resx, :resy

  def resx
    @resx ||= 1024
  end

  def resy
    @resy ||= 768
  end

  def nodes
    processes = Dir[parent.staged_dir.join("CTSPsubd*")].length
    processes.zero? ? 1 : (processes - 1) / ppn + 1
  end

  def ppn
    20
  end

  def hours
    @hours ||= 1
  end

  def staging_template_name
    "thermal"
  end

  def script_name
    "thermal_main.sh"
  end

  def host
    "ruby"
  end

  # Re-use staged dir from Session
  def stage
    FileUtils.cp_r staging_template_dir.to_s + "/.", self.staged_dir
    self.staged_dir
  end

  # Not responsible for deleting staged_dir
  def delete_staging
  end

  def submit_paraview
    job = PBS::Job.new(conn: PBS::Conn.batch('quick'))
    script = OSC::VNC::ScriptView.new(
      :vnc,
      'oakley',
      subtype: :shared,
      xstartup: Rails.root.join("jobs", "paraview", "xstartup"),
      outdir: File.join(AwesimRails.dataroot, "paraview"),
      geom: "#{resx}x#{resy}"
    )
    session = OSC::VNC::Session.new job, script

    session.submit(
      resources: {
        walltime: '08:00:00'
      },
      headers: {
        PBS::ATTR[:N] => "VFT-Thermal-Paraview",
      },
      envvars: {
        DATAFILE: staged_dir.join("ctsp.case")
      }
    )

    OSC::VNC::ConnView.new(session)
  end

  def warp3d_files_valid?
    files = %w(warp_temp_2_files.bin warp_temp_2_files.txt)
    if files.all? {|f| File.file? staged_dir.join(f)}
      return true
    else
      update_attribute(:fail_msg, "WARP3D input files were not generated")
      return false
    end
  end

  def paraview_files_valid?
    files = %w(ctsp.case ctsp.geom ctsp.mtemp ctsp.mtemp_wp)
    if files.all? {|f| File.file? staged_dir.join(f)}
      return true
    else
      update_attribute(:fail_msg, "Paraview input files were not generated")
      return false
    end
  end
end
