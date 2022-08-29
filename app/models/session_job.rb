class SessionJob < ApplicationRecord
  include OscMacheteRails::Statusable

  belongs_to :session

  # Just to be extra safe
  before_destroy { stop }

  # Determine if the results are valid
  def results_valid?
    session.finished!
  end

  # Destroy self if finished
  def update_status!(force: false)
    super(force: force)

    destroy if status.completed?
  end

  def job
    OSC::Machete::Job.new(
      script: script,
      pbsid: pbsid,
      host: 'owens', # FIXME: not configurable
      torque_helper: ResourceMgrAdapter.new(nil)
    )
  end
end
