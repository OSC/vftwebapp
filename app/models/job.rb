class Job < ActiveRecord::Base
  include OscMacheteRails::Statusable

  def results_valid?
    if File.file? workflow.error_path
      workflow.update_attribute(:fail_msg, File.read(workflow.error_path).strip)
      false
    else
      true
    end
  end
end
