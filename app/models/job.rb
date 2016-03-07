class Job < ActiveRecord::Base
  include OscMacheteRails::Statusable

  def results_valid?
    if File.file? workflow.error_file
      workflow.update_attribute(:fail_msg, File.read(workflow.error_file).strip)
      false
    else
      true
    end
  end

  def stop(update: true)
    workflow.update(fail_msg: 'User killed job') if update
    super(update: update)
  end
end
