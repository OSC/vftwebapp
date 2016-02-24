class Structural < Workflow
  has_many :jobs, class_name: "StructuralJob", foreign_key: "workflow_id", dependent: :destroy
  belongs_to :parent, class_name: "Thermal"

  def hours
    1
  end

  def staging_template_name
    "structural"
  end

  def script_name
    "structural_main.sh"
  end

  def host
    "ruby"
  end

  # Re-use staged dir from Thermal
  def stage
    staged_dir = parent.staged_dir
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
        PBS::ATTR[:N] => "VFT-Structural-Paraview"
      },
      envvars: {
        DATAFILE: staged_dir.join("wrp.exo")
      }
    )

    OSC::VNC::ConnView.new(session)
  end

  def paraview_files_valid?
    files = %w(wrp.exo)
    if files.all? {|f| File.file? staged_dir.join(f)}
      return true
    else
      update_attribute(:fail_msg, "Paraview input file was not generated")
      return false
    end
  end
end
