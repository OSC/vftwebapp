class Structural < Workflow
  has_many :jobs, class_name: "StructuralJob", foreign_key: "workflow_id", dependent: :destroy
  belongs_to :parent, class_name: "Thermal"

  # Set staged dir when first created
  before_create do
    self.staged_dir = parent.staged_dir
  end

  after_initialize do
    parse_warp3d_log_file if running?
  end

  attr_accessor :hours
  attr_accessor :resx, :resy
  attr_accessor :cur_profile, :num_profile

  def resx
    @resx ||= 1024
  end

  def resy
    @resy ||= 768
  end


  def hours
    @hours ||= 1
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

  def warp3d_input_file_name
    File.basename Dir.glob(staged_dir.join("*.wrp")).first
  end

  def warp3d_name
    File.basename(warp3d_input_file_name, ".wrp")
  end

  def warp3d_batch_messages
    "#{warp3d_name}.batch_messages"
  end

  def warp3d_batch_messages_file
    staged_dir.join warp3d_batch_messages
  end

  def parse_warp3d_log_file
    FileUtils.touch staged_dir.join("update")
    File.open(warp3d_batch_messages_file) do |f|
      lines = f.grep(/new profile/)
      self.cur_profile = lines.last.split[7].to_i unless lines.empty?
    end

    temp_file = staged_dir.join "warp_temp_2_files.txt"
    self.num_profile = IO.readlines(temp_file).last.split[0].to_i
  end

  # Re-use staged dir from Thermal
  def stage
    FileUtils.cp_r staging_template_dir.to_s + "/.", self.staged_dir
    self.staged_dir
  end

  # Clear out *.batch_messages
  def after_stage(staged_dir)
    super(staged_dir)
    warp3d_batch_messages_file.delete if warp3d_batch_messages_file.file?
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
      headers: {
        PBS::ATTR[:N] => "VFT-Structural-Paraview",
      },
      envvars: {
        DATAFILE: staged_dir.join("wrp.exo"),
        IS_STRUCTURAL: true
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

  # Check if solution diverged
  def soln_valid?
    parse_warp3d_log_file
    if cur_profile == num_profile
      return true
    else
      update_attribute(:fail_msg, "WARP3D solution may have diverged")
      return false
    end
  end
end
