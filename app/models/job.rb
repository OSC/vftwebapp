class Job < ActiveRecord::Base
  include OscMacheteRails::Statusable

  def results_valid?
    if File.file? workflow.error_path
      workflow.update_attribute(:error_list, YAML.load_file(workflow.error_path))
      false
    else
      workflow.update_attribute(:error_list, [])
      true
    end
  end
end
