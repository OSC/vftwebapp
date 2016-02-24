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
end
