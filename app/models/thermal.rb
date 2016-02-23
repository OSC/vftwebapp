class Thermal < Workflow
  has_many :jobs, class_name: "ThermalJob", foreign_key: "workflow_id", dependent: :destroy
  has_one :structural, foreign_key: "parent_id", dependent: :destroy
  belongs_to :parent, class_name: "Session"

  def nodes
    1
  end

  def hours
    1
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
    staged_dir = Pathname.new(parent.staged_dir)
    FileUtils.cp_r staging_template_dir.to_s + "/.", staged_dir
    staged_dir
  end

  def submit_paraview
    job = PBS::Job.new(conn: PBS::Conn.batch('quick'))
    script = OSC::VNC::ScriptView.new(
      :vnc,
      'oakley',
      subtype: :shared,
      xstartup: Rails.root.join("jobs", "paraview", "xstartup"),
      outdir: File.join(AwesimRails.dataroot, "paraview"),
      geom: '1024x768'
    )
    session = OSC::VNC::Session.new job, script

    session.submit(
      headers: {
        PBS::ATTR[:N] => "VFT-Thermal-Paraview"
      },
      envvars: {
        DATAFILE: File.join(staged_dir, "ctsp.case")
      }
    )

    OSC::VNC::ConnView.new(session)
  end
end
