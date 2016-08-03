class RestartFile
  include ActiveModel::Model
  include Comparable

  # the path to the uexternal file describing this object
  attr_accessor :file

  # current profile step of restart file
  attr_accessor :profile

  # current load step of restart file
  attr_accessor :step

  def initialize(attributes={})
    super
    @file = Pathname.new(@file)
    @profile ||= 0
    @step ||= 0

    /^save_at_completed_profile_(\d+)_step_(\d+).db$/.match(file_name) do
      @profile = $1.to_i
      @step = $2.to_i
    end if @file.file?
  end

  # Get file name of this wrp file
  def file_name
    file.basename.to_s
  end

  # Sortable by profile number
  def <=>(other)
    profile <=> other.profile
  end
end
