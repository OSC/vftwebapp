class ThermalStatusView < ViewModel
  def subject
    thermal
  end

  def msg
    if subject.active?
      "Submitted..."
    elsif subject.failed?
      subject.fail_msg
    end
  end
end
